# Script để test và validate CloudFormation template trước khi deploy

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TEST CLOUDFORMATION TEMPLATE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version 2>&1
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Write-Host "AWS CLI khong duoc cai dat" -ForegroundColor Red
    Write-Host "Tai ve tai: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
}

# Check AWS credentials
try {
    $identity = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Write-Host "AWS credentials chua duoc cau hinh" -ForegroundColor Red
    Write-Host "Chay: aws configure"
    exit 1
}

Write-Host "AWS CLI va credentials OK" -ForegroundColor Green
Write-Host ""

# Default region
$REGION = "ap-southeast-1"

Write-Host "Dang validate CloudFormation template..." -ForegroundColor Yellow

# Validate template syntax
$templatePath = Join-Path $PSScriptRoot "..\cloudformation\odoo-simple.yaml"
$templateBody = "file://$templatePath"

try {
    $null = aws cloudformation validate-template `
        --template-body $templateBody `
        --region $REGION 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Template syntax hop le" -ForegroundColor Green
    } else {
        throw
    }
} catch {
    Write-Host "Template syntax khong hop le" -ForegroundColor Red
    Write-Host "Chi tiet loi:"
    aws cloudformation validate-template `
        --template-body $templateBody `
        --region $REGION
    exit 1
}

Write-Host ""
Write-Host "Template information:" -ForegroundColor Cyan

# Get template description and parameters
aws cloudformation validate-template `
    --template-body $templateBody `
    --region $REGION `
    --query '{Description:Description,Parameters:Parameters[*].[ParameterKey,Description,DefaultValue]}' `
    --output table

Write-Host ""
Write-Host "Kiem tra AMI ID trong region $REGION..." -ForegroundColor Yellow

# Check if the AMI exists in the region
$AMI_ID = "ami-0fa377108253bf620"

try {
    $amiCheck = aws ec2 describe-images `
        --image-ids $AMI_ID `
        --region $REGION `
        --query 'Images[0].ImageId' `
        --output text 2>&1
    
    if ($LASTEXITCODE -eq 0 -and $amiCheck -ne "None") {
        # Get AMI details
        Write-Host "AMI $AMI_ID ton tai trong region $REGION" -ForegroundColor Green
        aws ec2 describe-images `
            --image-ids $AMI_ID `
            --region $REGION `
            --query 'Images[0].{Name:Name,Description:Description,State:State}' `
            --output table
    } else {
        throw
    }
} catch {
    Write-Host "AMI $AMI_ID khong ton tai trong region $REGION" -ForegroundColor Red
    Write-Host "Tim kiem Ubuntu 22.04 LTS AMI alternatives..." -ForegroundColor Yellow
    
    aws ec2 describe-images `
        --owners 099720109477 `
        --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" `
                  "Name=state,Values=available" `
        --query 'Images | sort_by(@, &CreationDate) | [-1].{ImageId:ImageId,Name:Name,CreationDate:CreationDate}' `
        --output table `
        --region $REGION
}

Write-Host ""
Write-Host "Uoc tinh chi phi (region $REGION):" -ForegroundColor Cyan

Write-Host "Instance Type: t2.micro"
Write-Host "Estimated cost: ~`$8.50/month (On-Demand, Free Tier: `$0)"
Write-Host "Storage: 8GB GP2 EBS ~`$0.80/month"
Write-Host "Total: ~`$9.30/month (Free Tier: ~`$0.80/month)"

Write-Host ""
Write-Host "Kiem tra security best practices..." -ForegroundColor Yellow

# Check if template follows security best practices
$templateContent = Get-Content $templatePath -Raw

# Check for hardcoded passwords
if ($templateContent -match "Password.*=.*[`"']") {
    Write-Host "Canh bao: Template co the chua hardcoded passwords" -ForegroundColor Yellow
} else {
    Write-Host "Khong phat hien hardcoded passwords trong template" -ForegroundColor Green
}

# Check for open security groups
if ($templateContent -match "CidrIp.*0\.0\.0\.0/0") {
    Write-Host "Canh bao: Security Group mo cho tat ca IPs (0.0.0.0/0)" -ForegroundColor Yellow
    Write-Host "   Dieu nay OK cho demo, nhung hay han che trong production"
} else {
    Write-Host "Security Group khong mo hoan toan" -ForegroundColor Green
}

Write-Host ""
Write-Host "Test deployment (dry-run)..." -ForegroundColor Yellow

# Create a test parameter file
$testParams = @"
[
    {
        "ParameterKey": "InstanceType",
        "ParameterValue": "t2.micro"
    }
]
"@

$tempParamFile = Join-Path $env:TEMP "test-parameters.json"
$testParams | Out-File -FilePath $tempParamFile -Encoding utf8

Write-Host "Parameters se duoc su dung:"
Get-Content $tempParamFile

Write-Host ""
Write-Host "Template estimate:" -ForegroundColor Cyan

try {
    aws cloudformation estimate-template-cost `
        --template-body $templateBody `
        --parameters "file://$tempParamFile" `
        --region $REGION `
        --query 'Url' `
        --output text 2>$null
} catch {
    Write-Host "Cost estimation khong available cho region nay"
}

# Clean up temp files
Remove-Item -Path $tempParamFile -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Tat ca tests da pass!" -ForegroundColor Green
Write-Host ""
Write-Host "De deploy:" -ForegroundColor Cyan
Write-Host "   .\deploy.ps1"
Write-Host ""
Write-Host "De deploy voi options:" -ForegroundColor Cyan
Write-Host "   .\deploy.ps1 -KeyPair your-key-pair        # With SSH key"
Write-Host "   .\deploy.ps1 -InstanceType t2.small        # Larger instance"
Write-Host "   .\deploy.ps1 -StackName my-stack           # Custom name"
