#!/bin/bash

# Script để cleanup/xóa CloudFormation stack và resources liên quan

set -e

echo "=========================================="
echo "🗑️  CLEANUP ODOO AWS RESOURCES"
echo "=========================================="

# Default values
STACK_NAME=""
REGION="ap-southeast-1"
FORCE=false

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
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            echo "Sử dụng: $0 [OPTIONS]"
            echo ""
            echo "OPTIONS:"
            echo "  -n, --name <name>     Tên CloudFormation stack"
            echo "  -r, --region <region> AWS region (mặc định: ap-southeast-1)"
            echo "  -f, --force           Không hỏi xác nhận"
            echo "  -h, --help            Hiển thị help này"
            echo ""
            echo "Ví dụ:"
            echo "  $0 -n odoo-community-18"
            echo "  $0 -n my-odoo-stack -f"
            exit 0
            ;;
        *)
            echo "❌ Tham số không hợp lệ: $1"
            echo "Sử dụng -h hoặc --help để xem hướng dẫn"
            exit 1
            ;;
    esac
done

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI không được cài đặt"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials chưa được cấu hình"
    echo "Chạy: aws configure"
    exit 1
fi

# If no stack name provided, list available stacks
if [[ -z "$STACK_NAME" ]]; then
    echo "📋 CloudFormation stacks có sẵn trong region $REGION:"
    echo ""

    # List stacks with Odoo in name
    STACKS=$(aws cloudformation list-stacks \
        --region $REGION \
        --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
        --query 'StackSummaries[?contains(StackName, `odoo`)].{Name:StackName,Status:StackStatus,Created:CreationTime}' \
        --output table 2>/dev/null || true)

    if [[ -n "$STACKS" && "$STACKS" != *"None"* ]]; then
        echo "$STACKS"
    else
        echo "Không tìm thấy stack nào có chứa 'odoo' trong tên"
        echo ""
        echo "Tất cả stacks:"
        aws cloudformation list-stacks \
            --region $REGION \
            --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
            --query 'StackSummaries[*].{Name:StackName,Status:StackStatus}' \
            --output table
    fi

    echo ""
    echo "Chạy lại với -n <stack-name> để xóa stack cụ thể"
    exit 0
fi

echo "🔍 Kiểm tra stack: $STACK_NAME trong region $REGION"

# Check if stack exists
if ! aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION &> /dev/null; then
    echo "❌ Stack '$STACK_NAME' không tồn tại trong region $REGION"
    exit 1
fi

# Get stack information
echo "📊 Thông tin stack:"
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].{Name:StackName,Status:StackStatus,Created:CreationTime}' \
    --output table

echo ""
echo "📦 Resources sẽ bị xóa:"
aws cloudformation list-stack-resources \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'StackResourceSummaries[*].{Type:ResourceType,LogicalId:LogicalResourceId,Status:ResourceStatus}' \
    --output table

# Get specific resource information for warning
INSTANCE_ID=$(aws cloudformation describe-stack-resources \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'StackResources[?ResourceType==`AWS::EC2::Instance`].PhysicalResourceId' \
    --output text 2>/dev/null || echo "")

if [[ -n "$INSTANCE_ID" && "$INSTANCE_ID" != "None" ]]; then
    echo ""
    echo "⚠️  CẢNH BÁO:"
    echo "• Instance ID: $INSTANCE_ID sẽ bị TERMINATE"
    echo "• Tất cả dữ liệu trong instance sẽ bị MẤT"
    echo "• Database, files, logs sẽ bị XÓA hoàn toàn"
    echo "• Không thể khôi phục sau khi xóa"

    # Check if instance is running
    INSTANCE_STATE=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --region $REGION \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text 2>/dev/null || echo "unknown")

    if [[ "$INSTANCE_STATE" == "running" ]]; then
        echo "• Instance đang RUNNING - có thể có người đang sử dụng"
    fi
fi

echo ""

# Confirmation
if [[ "$FORCE" == "false" ]]; then
    echo "❓ Bạn có CHẮC CHẮN muốn xóa stack '$STACK_NAME'?"
    echo "   Nhập 'yes' để xác nhận, bất kỳ gì khác để hủy:"
    read -p "> " confirm

    if [[ "$confirm" != "yes" ]]; then
        echo "❌ Cleanup bị hủy bởi người dùng"
        exit 0
    fi
fi

echo ""
echo "🗑️  Bắt đầu xóa stack '$STACK_NAME'..."

# Delete the stack
aws cloudformation delete-stack \
    --stack-name $STACK_NAME \
    --region $REGION

if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi xóa stack"
    exit 1
fi

echo "✅ Lệnh delete-stack đã được gửi"
echo ""
echo "⏳ Đang chờ stack bị xóa hoàn toàn..."
echo "   (Có thể mất 2-5 phút)"

# Wait for stack deletion to complete
aws cloudformation wait stack-delete-complete \
    --stack-name $STACK_NAME \
    --region $REGION

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Stack '$STACK_NAME' đã được xóa thành công!"
else
    echo ""
    echo "⚠️  Có thể có lỗi trong quá trình xóa stack"
    echo "Kiểm tra AWS Console để xem chi tiết"

    # Try to get the current status
    CURRENT_STATUS=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].StackStatus' \
        --output text 2>/dev/null || echo "DELETED")

    if [[ "$CURRENT_STATUS" == "DELETE_FAILED" ]]; then
        echo ""
        echo "❌ Stack delete FAILED. Kiểm tra lỗi:"
        aws cloudformation describe-stack-events \
            --stack-name $STACK_NAME \
            --region $REGION \
            --query 'StackEvents[?ResourceStatus==`DELETE_FAILED`].{Resource:LogicalResourceId,Reason:ResourceStatusReason}' \
            --output table
    fi
fi

echo ""
echo "🔍 Kiểm tra cleanup còn sót lại gì không..."

# Check for any remaining resources (orphaned resources)
echo "Checking for orphaned EC2 instances..."
ORPHANED_INSTANCES=$(aws ec2 describe-instances \
    --region $REGION \
    --filters "Name=tag:aws:cloudformation:stack-name,Values=$STACK_NAME" \
    --query 'Reservations[*].Instances[?State.Name!=`terminated`].InstanceId' \
    --output text 2>/dev/null || echo "")

if [[ -n "$ORPHANED_INSTANCES" && "$ORPHANED_INSTANCES" != "None" ]]; then
    echo "⚠️  Tìm thấy orphaned instances: $ORPHANED_INSTANCES"
    echo "Có thể cần xóa thủ công"
else
    echo "✅ Không có orphaned instances"
fi

echo ""
echo "📊 Cleanup summary:"
echo "• Stack: $STACK_NAME - DELETED"
echo "• Region: $REGION"
echo "• Time: $(date)"

echo ""
echo "✅ Cleanup hoàn thành!"
echo ""
echo "💡 Lưu ý:"
echo "• Backup data nếu có không thể khôi phục"
echo "• Billing có thể vẫn hiện instance charge trong vài giờ"
echo "• EBS snapshots (nếu có) có thể vẫn tồn tại và tính phí"