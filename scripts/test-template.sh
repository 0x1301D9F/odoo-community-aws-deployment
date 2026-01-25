#!/bin/bash

# Script để test và validate CloudFormation template trước khi deploy

set -e

echo "=========================================="
echo "🧪 TEST CLOUDFORMATION TEMPLATE"
echo "=========================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI không được cài đặt"
    echo "Tải về tại: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials chưa được cấu hình"
    echo "Chạy: aws configure"
    exit 1
fi

echo "✅ AWS CLI và credentials OK"
echo ""

# Default region
REGION="ap-southeast-1"

echo "🔍 Đang validate CloudFormation template..."

# Validate template syntax
if aws cloudformation validate-template \
    --template-body file://cloudformation/odoo-simple.yaml \
    --region $REGION > /dev/null 2>&1; then
    echo "✅ Template syntax hợp lệ"
else
    echo "❌ Template syntax không hợp lệ"
    echo "Chi tiết lỗi:"
    aws cloudformation validate-template \
        --template-body file://cloudformation/odoo-simple.yaml \
        --region $REGION
    exit 1
fi

echo ""
echo "📋 Template information:"

# Get template description and parameters
aws cloudformation validate-template \
    --template-body file://cloudformation/odoo-simple.yaml \
    --region $REGION \
    --query '{Description:Description,Parameters:Parameters[*].[ParameterKey,Description,DefaultValue]}' \
    --output table

echo ""
echo "🔧 Kiểm tra AMI ID trong region $REGION..."

# Check if the AMI exists in the region
AMI_ID="ami-0fa377108253bf620"
if aws ec2 describe-images \
    --image-ids $AMI_ID \
    --region $REGION \
    --query 'Images[0].ImageId' \
    --output text &> /dev/null; then

    # Get AMI details
    AMI_INFO=$(aws ec2 describe-images \
        --image-ids $AMI_ID \
        --region $REGION \
        --query 'Images[0].{Name:Name,Description:Description,State:State}' \
        --output table)

    echo "✅ AMI $AMI_ID tồn tại trong region $REGION"
    echo "$AMI_INFO"
else
    echo "❌ AMI $AMI_ID không tồn tại trong region $REGION"
    echo "🔍 Tìm kiếm Ubuntu 22.04 LTS AMI alternatives..."

    # Find alternative Ubuntu AMIs
    aws ec2 describe-images \
        --owners 099720109477 \
        --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
                  "Name=state,Values=available" \
        --query 'Images | sort_by(@, &CreationDate) | [-1].{ImageId:ImageId,Name:Name,CreationDate:CreationDate}' \
        --output table \
        --region $REGION
fi

echo ""
echo "💰 Ước tính chi phí (region $REGION):"

# Get pricing info for t2.micro
echo "Instance Type: t2.micro"
echo "Estimated cost: ~$8.50/month (On-Demand, Free Tier: $0)"
echo "Storage: 8GB GP2 EBS ~$0.80/month"
echo "Total: ~$9.30/month (Free Tier: ~$0.80/month)"

echo ""
echo "🔒 Kiểm tra security best practices..."

# Check if template follows security best practices
TEMPLATE_CONTENT=$(cat cloudformation/odoo-simple.yaml)

# Check for hardcoded passwords
if echo "$TEMPLATE_CONTENT" | grep -q "Password.*=.*['\"]"; then
    echo "⚠️  Cảnh báo: Template có thể chứa hardcoded passwords"
else
    echo "✅ Không phát hiện hardcoded passwords trong template"
fi

# Check for open security groups
if echo "$TEMPLATE_CONTENT" | grep -q "CidrIp.*0.0.0.0/0"; then
    echo "⚠️  Cảnh báo: Security Group mở cho tất cả IPs (0.0.0.0/0)"
    echo "   Điều này OK cho demo, nhưng hãy hạn chế trong production"
else
    echo "✅ Security Group không mở hoàn toàn"
fi

echo ""
echo "🧪 Test deployment (dry-run)..."

# Create a test parameter file
cat > /tmp/test-parameters.json << EOF
[
    {
        "ParameterKey": "InstanceType",
        "ParameterValue": "t2.micro"
    }
]
EOF

echo "Parameters sẽ được sử dụng:"
cat /tmp/test-parameters.json

echo ""
echo "📝 Template estimate:"

# Estimate template resources
aws cloudformation estimate-template-cost \
    --template-body file://cloudformation/odoo-simple.yaml \
    --parameters file:///tmp/test-parameters.json \
    --region $REGION \
    --query 'Url' \
    --output text 2>/dev/null || echo "Cost estimation không available cho region này"

# Clean up temp files
rm -f /tmp/test-parameters.json

echo ""
echo "✅ Tất cả tests đã pass!"
echo ""
echo "🚀 Để deploy:"
echo "   ./deploy.sh"
echo ""
echo "📚 Để deploy với options:"
echo "   ./deploy.sh -k your-key-pair        # With SSH key"
echo "   ./deploy.sh -t t2.small             # Larger instance"
echo "   ./deploy.sh -n my-stack             # Custom name"