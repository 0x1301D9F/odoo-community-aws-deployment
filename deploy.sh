#!/bin/bash

# Script deploy Odoo Community 18 lên AWS
# Sử dụng CloudFormation template để tạo hạ tầng hoàn chỉnh

set -e  # Exit on error

echo "=========================================="
echo "🚀 DEPLOY ODOO COMMUNITY 18 LÊN AWS"
echo "=========================================="

# Kiểm tra AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI không được cài đặt. Vui lòng cài đặt AWS CLI trước."
    echo "Hướng dẫn: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Kiểm tra AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials chưa được cấu hình."
    echo "Chạy: aws configure"
    exit 1
fi

# Default values
STACK_NAME="odoo-community-18"
REGION="ap-southeast-1"
INSTANCE_TYPE="t2.micro"
KEY_PAIR=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            STACK_NAME="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -t|--type)
            INSTANCE_TYPE="$2"
            shift 2
            ;;
        -k|--key)
            KEY_PAIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Sử dụng: $0 [OPTIONS]"
            echo ""
            echo "OPTIONS:"
            echo "  -n, --name <name>     Tên CloudFormation stack (mặc định: odoo-community-18)"
            echo "  -r, --region <region> AWS region (mặc định: ap-southeast-1)"
            echo "  -t, --type <type>     Instance type (mặc định: t2.micro)"
            echo "  -k, --key <keyname>   EC2 Key Pair name cho SSH access"
            echo "  -h, --help            Hiển thị help này"
            echo ""
            echo "Ví dụ:"
            echo "  $0                              # Deploy với settings mặc định"
            echo "  $0 -k my-key-pair               # Deploy với SSH key"
            echo "  $0 -n my-odoo -t t2.small       # Deploy với custom name và instance type"
            exit 0
            ;;
        *)
            echo "❌ Tham số không hợp lệ: $1"
            echo "Sử dụng -h hoặc --help để xem hướng dẫn"
            exit 1
            ;;
    esac
done

echo "📋 Thông tin deployment:"
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo "Instance Type: $INSTANCE_TYPE"
if [ -n "$KEY_PAIR" ]; then
    echo "Key Pair: $KEY_PAIR"
else
    echo "Key Pair: Không sử dụng (SSH sẽ không available)"
fi
echo ""

# Confirmation
read -p "Bạn có muốn tiếp tục deploy? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "❌ Deploy bị hủy bởi người dùng"
    exit 0
fi

echo ""
echo "🔍 Kiểm tra CloudFormation template..."

# Validate template
aws cloudformation validate-template \
    --template-body file://cloudformation/odoo-simple.yaml \
    --region $REGION

if [ $? -ne 0 ]; then
    echo "❌ CloudFormation template không hợp lệ"
    exit 1
fi

echo "✅ Template hợp lệ"

# Prepare parameters
PARAMETERS=""
if [ -n "$KEY_PAIR" ]; then
    PARAMETERS="ParameterKey=KeyPairName,ParameterValue=$KEY_PAIR ParameterKey=InstanceType,ParameterValue=$INSTANCE_TYPE"
else
    PARAMETERS="ParameterKey=InstanceType,ParameterValue=$INSTANCE_TYPE"
fi

echo ""
echo "🚀 Bắt đầu deploy CloudFormation stack..."

# Deploy stack
aws cloudformation create-stack \
    --stack-name $STACK_NAME \
    --template-body file://cloudformation/odoo-simple.yaml \
    --parameters $PARAMETERS \
    --region $REGION \
    --capabilities CAPABILITY_IAM

if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi tạo CloudFormation stack"
    exit 1
fi

echo "✅ CloudFormation stack được tạo thành công"
echo ""
echo "⏳ Đang chờ stack deploy hoàn thành..."
echo "   Thời gian ước tính: 5-10 phút"

# Wait for stack completion
aws cloudformation wait stack-create-complete \
    --stack-name $STACK_NAME \
    --region $REGION

if [ $? -ne 0 ]; then
    echo "❌ Stack deploy thất bại hoặc timeout"
    echo "Kiểm tra AWS Console để xem chi tiết lỗi"
    exit 1
fi

echo ""
echo "🎉 Deploy thành công!"
echo ""

# Get outputs
echo "📊 Thông tin hệ thống:"
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
    --output table

echo ""
echo "🔗 Lấy thông tin truy cập:"

# Get specific outputs
INSTANCE_IP=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`InstancePublicIP`].OutputValue' \
    --output text)

ODOO_URL=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`OdooURL`].OutputValue' \
    --output text)

echo ""
echo "=========================================="
echo "🎯 THÔNG TIN TRUY CẬP ODOO"
echo "=========================================="
echo "🌐 URL Odoo:     $ODOO_URL"
echo "🌐 URL Nginx:    http://$INSTANCE_IP"
echo "🗃️  Database:    odoo18"
echo "👤 Admin User:   admin"
echo "🔐 Admin Pass:   admin123"
if [ -n "$KEY_PAIR" ]; then
    echo "🔧 SSH Command:  ssh ubuntu@$INSTANCE_IP"
fi
echo "=========================================="

echo ""
echo "📝 Ghi chú:"
echo "• Đợi 2-3 phút để Odoo khởi động hoàn toàn"
echo "• Nếu không truy cập được, kiểm tra Security Groups"
echo "• Để xóa stack: aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION"

echo ""
echo "✅ Deploy hoàn thành!"