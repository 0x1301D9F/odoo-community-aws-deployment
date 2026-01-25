# Script deploy Odoo Community 18 lên AWS
# Su dung CloudFormation template de tao ha tang hoan chinh

param(
    [Alias("n")]
    [string]$Name = "odoo-community-18",
    
    [Alias("r")]
    [string]$Region = "ap-southeast-1",
    
    [Alias("t")]
    [string]$InstanceType = "t2.micro",
    
    [Alias("k")]
    [string]$KeyPair = "",
    
    [Alias("h")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help) {
    Write-Host "Su dung: .\deploy.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "OPTIONS:"
    Write-Host "  -Name, -n <name>           Ten CloudFormation stack (mac dinh: odoo-community-18)"
    Write-Host "  -Region, -r <region>       AWS region (mac dinh: ap-southeast-1)"
    Write-Host "  -InstanceType, -t <type>   Instance type (mac dinh: t2.micro)"
    Write-Host "  -KeyPair, -k <keyname>     EC2 Key Pair name cho SSH access"
    Write-Host "  -Help, -h                  Hien thi help nay"
    Write-Host ""
    Write-Host "Vi du:"
    Write-Host "  .\deploy.ps1                              # Deploy voi settings mac dinh"
    Write-Host "  .\deploy.ps1 -KeyPair my-key-pair         # Deploy voi SSH key"
    Write-Host "  .\deploy.ps1 -Name my-odoo -InstanceType t2.small  # Custom name va instance"
    exit 0
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "DEPLOY ODOO COMMUNITY 18 LEN AWS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Kiem tra AWS CLI
try {
    $null = aws --version 2>&1
    if ($LASTEXITCODE -ne 0) { throw }
}
catch {
    Write-Host "AWS CLI khong duoc cai dat. Vui long cai dat AWS CLI truoc." -ForegroundColor Red
    Write-Host "Huong dan: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
}

# Kiem tra AWS credentials
try {
    $null = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -ne 0) { throw }
}
catch {
    Write-Host "AWS credentials chua duoc cau hinh." -ForegroundColor Red
    Write-Host "Chay: aws configure"
    exit 1
}

Write-Host "Thong tin deployment:" -ForegroundColor Cyan
Write-Host "Stack Name: $Name"
Write-Host "Region: $Region"
Write-Host "Instance Type: $InstanceType"
if ($KeyPair) {
    Write-Host "Key Pair: $KeyPair"
}
else {
    Write-Host "Key Pair: Khong su dung (SSH se khong available)"
}
Write-Host ""

# Confirmation
$confirm = Read-Host "Ban co muon tiep tuc deploy? (y/N)"
if ($confirm -notmatch "^[Yy]$") {
    Write-Host "Deploy bi huy boi nguoi dung" -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "Kiem tra CloudFormation template..." -ForegroundColor Yellow

# Validate template
$templatePath = Join-Path $PSScriptRoot "..\cloudformation\odoo-simple.yaml"
$templateBody = "file://$templatePath"

try {
    $null = aws cloudformation validate-template --template-body $templateBody --region $Region 2>&1
    if ($LASTEXITCODE -ne 0) { throw }
    Write-Host "Template hop le" -ForegroundColor Green
}
catch {
    Write-Host "CloudFormation template khong hop le" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Bat dau deploy CloudFormation stack..." -ForegroundColor Yellow

# Deploy stack
try {
    if ($KeyPair) {
        aws cloudformation create-stack `
            --stack-name $Name `
            --template-body $templateBody `
            --parameters "ParameterKey=InstanceType,ParameterValue=$InstanceType" "ParameterKey=KeyPairName,ParameterValue=$KeyPair" `
            --region $Region `
            --capabilities CAPABILITY_IAM
    } else {
        aws cloudformation create-stack `
            --stack-name $Name `
            --template-body $templateBody `
            --parameters "ParameterKey=InstanceType,ParameterValue=$InstanceType" `
            --region $Region `
            --capabilities CAPABILITY_IAM
    }
    if ($LASTEXITCODE -ne 0) { throw }
}
catch {
    Write-Host "Loi khi tao CloudFormation stack" -ForegroundColor Red
    exit 1
}


Write-Host "CloudFormation stack duoc tao thanh cong" -ForegroundColor Green
Write-Host ""
Write-Host "Dang cho stack deploy hoan thanh..." -ForegroundColor Yellow
Write-Host "   Thoi gian uoc tinh: 5-10 phut"

# Wait for stack completion
aws cloudformation wait stack-create-complete --stack-name $Name --region $Region

if ($LASTEXITCODE -ne 0) {
    Write-Host "Stack deploy that bai hoac timeout" -ForegroundColor Red
    Write-Host "Kiem tra AWS Console de xem chi tiet loi"
    exit 1
}

Write-Host ""
Write-Host "Deploy thanh cong!" -ForegroundColor Green
Write-Host ""

# Get outputs
Write-Host "Thong tin he thong:" -ForegroundColor Cyan
aws cloudformation describe-stacks `
    --stack-name $Name `
    --region $Region `
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' `
    --output table

Write-Host ""
Write-Host "Lay thong tin truy cap:" -ForegroundColor Cyan

# Get specific outputs
$instanceIP = aws cloudformation describe-stacks `
    --stack-name $Name `
    --region $Region `
    --query 'Stacks[0].Outputs[?OutputKey==`InstancePublicIP`].OutputValue' `
    --output text

$odooURL = aws cloudformation describe-stacks `
    --stack-name $Name `
    --region $Region `
    --query 'Stacks[0].Outputs[?OutputKey==`OdooURL`].OutputValue' `
    --output text

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "THONG TIN TRUY CAP ODOO" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "URL Odoo:     $odooURL"
Write-Host "URL Nginx:    http://$instanceIP"
Write-Host "Database:     odoo18"
Write-Host "Admin User:   admin"
Write-Host "Admin Pass:   admin123"
if ($KeyPair) {
    Write-Host "SSH Command:  ssh ubuntu@$instanceIP"
}
Write-Host "==========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Ghi chu:" -ForegroundColor Yellow
Write-Host "* Doi 2-3 phut de Odoo khoi dong hoan toan"
Write-Host "* Neu khong truy cap duoc, kiem tra Security Groups"
Write-Host "* De xoa stack: aws cloudformation delete-stack --stack-name $Name --region $Region"

Write-Host ""
Write-Host "Deploy hoan thanh!" -ForegroundColor Green
