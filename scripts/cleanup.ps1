# Script de cleanup/xoa CloudFormation stack va resources lien quan

param(
    [Alias("n")]
    [string]$Name = "",
    
    [Alias("r")]
    [string]$Region = "ap-southeast-1",
    
    [Alias("f")]
    [switch]$Force,
    
    [Alias("h")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help) {
    Write-Host "Su dung: .\cleanup.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "OPTIONS:"
    Write-Host "  -Name, -n <name>       Ten CloudFormation stack"
    Write-Host "  -Region, -r <region>   AWS region (mac dinh: ap-southeast-1)"
    Write-Host "  -Force, -f             Khong hoi xac nhan"
    Write-Host "  -Help, -h              Hien thi help nay"
    Write-Host ""
    Write-Host "Vi du:"
    Write-Host "  .\cleanup.ps1 -Name odoo-community-18"
    Write-Host "  .\cleanup.ps1 -Name my-odoo-stack -Force"
    exit 0
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "CLEANUP ODOO AWS RESOURCES" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check AWS CLI
try {
    $null = aws --version 2>&1
    if ($LASTEXITCODE -ne 0) { throw }
}
catch {
    Write-Host "AWS CLI khong duoc cai dat" -ForegroundColor Red
    exit 1
}

# Check AWS credentials
try {
    $null = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -ne 0) { throw }
}
catch {
    Write-Host "AWS credentials chua duoc cau hinh" -ForegroundColor Red
    Write-Host "Chay: aws configure"
    exit 1
}

# If no stack name provided, list available stacks
if (-not $Name) {
    Write-Host "CloudFormation stacks co san trong region $Region`:" -ForegroundColor Cyan
    Write-Host ""
    
    $stacks = aws cloudformation list-stacks `
        --region $Region `
        --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE `
        --query 'StackSummaries[?contains(StackName, `odoo`)].{Name:StackName,Status:StackStatus,Created:CreationTime}' `
        --output table 2>$null
    
    if ($stacks -and $stacks -notmatch "None") {
        Write-Host $stacks
    }
    else {
        Write-Host "Khong tim thay stack nao co chua 'odoo' trong ten"
        Write-Host ""
        Write-Host "Tat ca stacks:"
        aws cloudformation list-stacks `
            --region $Region `
            --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE `
            --query 'StackSummaries[*].{Name:StackName,Status:StackStatus}' `
            --output table
    }
    
    Write-Host ""
    Write-Host "Chay lai voi -Name <stack-name> de xoa stack cu the"
    exit 0
}

Write-Host "Kiem tra stack: $Name trong region $Region" -ForegroundColor Yellow

# Check if stack exists
try {
    $null = aws cloudformation describe-stacks --stack-name $Name --region $Region 2>&1
    if ($LASTEXITCODE -ne 0) { throw }
}
catch {
    Write-Host "Stack '$Name' khong ton tai trong region $Region" -ForegroundColor Red
    exit 1
}

# Get stack information
Write-Host "Thong tin stack:" -ForegroundColor Cyan
aws cloudformation describe-stacks `
    --stack-name $Name `
    --region $Region `
    --query 'Stacks[0].{Name:StackName,Status:StackStatus,Created:CreationTime}' `
    --output table

Write-Host ""
Write-Host "Resources se bi xoa:" -ForegroundColor Cyan
aws cloudformation list-stack-resources `
    --stack-name $Name `
    --region $Region `
    --query 'StackResourceSummaries[*].{Type:ResourceType,LogicalId:LogicalResourceId,Status:ResourceStatus}' `
    --output table

# Get instance ID for warning
$instanceId = aws cloudformation describe-stack-resources `
    --stack-name $Name `
    --region $Region `
    --query 'StackResources[?ResourceType==`AWS::EC2::Instance`].PhysicalResourceId' `
    --output text 2>$null

if ($instanceId -and $instanceId -ne "None") {
    Write-Host ""
    Write-Host "CANH BAO:" -ForegroundColor Yellow
    Write-Host "* Instance ID: $instanceId se bi TERMINATE"
    Write-Host "* Tat ca du lieu trong instance se bi MAT"
    Write-Host "* Database, files, logs se bi XOA hoan toan"
    Write-Host "* Khong the khoi phuc sau khi xoa"
    
    # Check instance state
    $instanceState = aws ec2 describe-instances `
        --instance-ids $instanceId `
        --region $Region `
        --query 'Reservations[0].Instances[0].State.Name' `
        --output text 2>$null
    
    if ($instanceState -eq "running") {
        Write-Host "* Instance dang RUNNING - co the co nguoi dang su dung" -ForegroundColor Yellow
    }
}

Write-Host ""

# Confirmation
if (-not $Force) {
    Write-Host "Ban co CHAC CHAN muon xoa stack '$Name'?" -ForegroundColor Yellow
    $confirm = Read-Host "Nhap 'yes' de xac nhan, bat ky gi khac de huy"
    
    if ($confirm -ne "yes") {
        Write-Host "Cleanup bi huy boi nguoi dung" -ForegroundColor Red
        exit 0
    }
}

Write-Host ""
Write-Host "Bat dau xoa stack '$Name'..." -ForegroundColor Yellow

# Delete the stack
aws cloudformation delete-stack --stack-name $Name --region $Region

if ($LASTEXITCODE -ne 0) {
    Write-Host "Loi khi xoa stack" -ForegroundColor Red
    exit 1
}

Write-Host "Lenh delete-stack da duoc gui" -ForegroundColor Green
Write-Host ""
Write-Host "Dang cho stack bi xoa hoan toan..." -ForegroundColor Yellow
Write-Host "   (Co the mat 2-5 phut)"

# Wait for stack deletion
aws cloudformation wait stack-delete-complete --stack-name $Name --region $Region

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Stack '$Name' da duoc xoa thanh cong!" -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "Co the co loi trong qua trinh xoa stack" -ForegroundColor Yellow
    Write-Host "Kiem tra AWS Console de xem chi tiet"
}

Write-Host ""
Write-Host "Kiem tra cleanup con sot lai gi khong..." -ForegroundColor Yellow

# Check for orphaned resources
Write-Host "Checking for orphaned EC2 instances..."
$orphanedInstances = aws ec2 describe-instances `
    --region $Region `
    --filters "Name=tag:aws:cloudformation:stack-name,Values=$Name" `
    --query 'Reservations[*].Instances[?State.Name!=`terminated`].InstanceId' `
    --output text 2>$null

if ($orphanedInstances -and $orphanedInstances -ne "None") {
    Write-Host "Tim thay orphaned instances: $orphanedInstances" -ForegroundColor Yellow
    Write-Host "Co the can xoa thu cong"
}
else {
    Write-Host "Khong co orphaned instances" -ForegroundColor Green
}

Write-Host ""
Write-Host "Cleanup summary:" -ForegroundColor Cyan
Write-Host "* Stack: $Name - DELETED"
Write-Host "* Region: $Region"
Write-Host "* Time: $(Get-Date)"

Write-Host ""
Write-Host "Cleanup hoan thanh!" -ForegroundColor Green
Write-Host ""
Write-Host "Luu y:" -ForegroundColor Yellow
Write-Host "* Backup data neu co khong the khoi phuc"
Write-Host "* Billing co the van hien instance charge trong vai gio"
Write-Host "* EBS snapshots (neu co) co the van ton tai va tinh phi"
