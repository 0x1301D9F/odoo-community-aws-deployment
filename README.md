# Odoo Community 18 trên AWS EC2 - Deploy Đơn giản và Chi phí Thấp

🎯 **Mục tiêu**: Deploy Odoo Community 18 trên AWS EC2 với chi phí thấp nhất có thể, sử dụng CloudFormation để tự động hóa hoàn toàn.

## 📋 Tổng quan

Dự án này cung cấp giải pháp deploy Odoo Community 18 lên AWS EC2 một cách đơn giản, nhanh chóng và tiết kiệm chi phí. Tất cả được tự động hóa bằng CloudFormation và bash scripts.

### ✨ Tính năng

- ✅ **Hoàn toàn tự động**: Một lệnh deploy tất cả
- ✅ **Chi phí thấp**: Sử dụng t2.micro (Free Tier eligible)
- ✅ **Đơn giản**: Không cần domain name, SSL phức tạp
- ✅ **Sẵn sàng sử dụng**: Database và admin user đã được cấu hình
- ✅ **Monitoring**: Logs và health checks cơ bản

### 🏗️ Kiến trúc

```
Internet
    ↓
[Security Group] - Port 22, 80, 8069
    ↓
[EC2 t2.micro - Ubuntu 22.04]
    ├── Nginx (Port 80) → Odoo (Port 8069)
    ├── Odoo Community 18
    └── PostgreSQL 14
```

## 🚀 Quick Start

### Bước 1: Chuẩn bị môi trường

```bash
# 1. Cài đặt AWS CLI (nếu chưa có)
# Windows: https://awscli.amazonaws.com/AWSCLIV2.msi
# macOS: brew install awscli
# Linux: sudo apt install awscli

# 2. Cấu hình AWS credentials
aws configure
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region name: ap-southeast-1
# Default output format: json

# 3. Verify cấu hình
aws sts get-caller-identity
```

### Bước 2: Clone repository

```bash
git clone <repository-url>
cd odoo-aws-deployment
```

### Bước 3: Deploy (Cách đơn giản nhất)

```bash
# Deploy với settings mặc định
chmod +x deploy.sh
./deploy.sh
```

### Bước 4: Truy cập Odoo

Sau khi deploy thành công (5-10 phút), bạn sẽ nhận được:

```
🎯 THÔNG TIN TRUY CẬP ODOO
========================================
🌐 URL Odoo:     http://[IP]:8069
🌐 URL Nginx:    http://[IP]
🗃️  Database:    odoo18
👤 Admin User:   admin
🔐 Admin Pass:   admin123
========================================
```

## 📚 Hướng dẫn Chi tiết

### Deploy với tùy chọn

```bash
# Deploy với SSH key để có thể SSH vào server
./deploy.sh -k my-key-pair

# Deploy với instance type lớn hơn
./deploy.sh -t t2.small

# Deploy với custom stack name
./deploy.sh -n my-odoo-stack

# Deploy với tất cả options
./deploy.sh -n my-odoo -t t2.small -k my-key -r ap-southeast-1
```

### Các tùy chọn deploy

| Tham số | Mô tả | Mặc định |
|---------|-------|----------|
| `-n, --name` | Tên CloudFormation stack | `odoo-community-18` |
| `-r, --region` | AWS region | `ap-southeast-1` |
| `-t, --type` | EC2 instance type | `t2.micro` |
| `-k, --key` | EC2 Key Pair name | Không dùng |

### Deploy thủ công bằng AWS CLI

```bash
# 1. Validate template
aws cloudformation validate-template \
    --template-body file://cloudformation/odoo-simple.yaml

# 2. Deploy stack
aws cloudformation create-stack \
    --stack-name odoo-community-18 \
    --template-body file://cloudformation/odoo-simple.yaml \
    --parameters ParameterKey=InstanceType,ParameterValue=t2.micro \
    --region ap-southeast-1

# 3. Monitor deployment
aws cloudformation describe-stack-events \
    --stack-name odoo-community-18

# 4. Get outputs khi deploy xong
aws cloudformation describe-stacks \
    --stack-name odoo-community-18 \
    --query 'Stacks[0].Outputs'
```

### Deploy qua AWS Console

1. Đăng nhập AWS Console
2. Vào CloudFormation service
3. Click "Create stack" → "With new resources"
4. Upload file `cloudformation/odoo-simple.yaml`
5. Điền parameters (instance type, key pair)
6. Click "Create stack"
7. Đợi deploy hoàn thành (~10 phút)

## 🔧 Quản lý Hệ thống

### SSH vào server (nếu có key pair)

```bash
# Lấy IP từ CloudFormation outputs
aws cloudformation describe-stacks \
    --stack-name odoo-community-18 \
    --query 'Stacks[0].Outputs[?OutputKey==`InstancePublicIP`].OutputValue' \
    --output text

# SSH vào server
ssh ubuntu@[IP_ADDRESS]
```

### Kiểm tra services

```bash
# Kiểm tra Odoo service
sudo systemctl status odoo

# Xem logs Odoo
sudo tail -f /var/log/odoo/odoo.log

# Kiểm tra Nginx
sudo systemctl status nginx
sudo tail -f /var/log/nginx/odoo.access.log

# Kiểm tra PostgreSQL
sudo systemctl status postgresql
sudo -u postgres psql -c "\l"  # List databases
```

### Restart services

```bash
# Restart Odoo
sudo systemctl restart odoo

# Restart Nginx
sudo systemctl restart nginx

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### Quản lý database

```bash
# Kết nối PostgreSQL
sudo -u postgres psql

# Kết nối database odoo18
sudo -u postgres psql -d odoo18

# Backup database
sudo -u postgres pg_dump odoo18 > odoo18_backup.sql

# Restore database
sudo -u postgres psql odoo18 < odoo18_backup.sql
```

## 📊 Monitoring và Troubleshooting

### Kiểm tra health

```bash
# Kiểm tra Odoo đang chạy
curl http://[IP]:8069/web/health

# Kiểm tra Nginx
curl http://[IP]/health

# Kiểm tra từ bên ngoài
curl -I http://[IP]
```

### Common issues

#### 🚫 Không truy cập được Odoo

```bash
# 1. Kiểm tra Security Group
aws ec2 describe-security-groups \
    --group-ids [SG_ID] \
    --query 'SecurityGroups[0].IpPermissions'

# 2. Kiểm tra Odoo service
ssh ubuntu@[IP]
sudo systemctl status odoo
sudo journalctl -u odoo -f

# 3. Kiểm tra port
sudo netstat -tlnp | grep 8069
```

#### 🚫 Database connection error

```bash
# Kiểm tra PostgreSQL
sudo systemctl status postgresql

# Kiểm tra database tồn tại
sudo -u postgres psql -c "\l" | grep odoo18

# Kiểm tra user tồn tại
sudo -u postgres psql -c "\du" | grep odoo

# Reset database password
sudo -u postgres psql -c "ALTER USER odoo WITH PASSWORD 'odoo123';"
```

#### 🚫 Nginx 502 error

```bash
# Kiểm tra Nginx config
sudo nginx -t

# Xem error logs
sudo tail -f /var/log/nginx/error.log

# Restart Nginx
sudo systemctl restart nginx
```

### Log locations

```bash
# Odoo logs
/var/log/odoo/odoo.log

# Nginx logs
/var/log/nginx/odoo.access.log
/var/log/nginx/odoo.error.log

# System logs
sudo journalctl -u odoo
sudo journalctl -u nginx
sudo journalctl -u postgresql

# User data logs (installation)
/var/log/user-data.log
```

## 💰 Chi phí và Tối ưu hóa

### Chi phí dự kiến (ap-southeast-1)

| Resource | Loại | Chi phí/tháng |
|----------|------|---------------|
| EC2 t2.micro | On-Demand | $8.50 (Free Tier: $0) |
| EBS 8GB GP2 | Storage | $0.80 |
| Data Transfer | Outbound | $0.09/GB |
| **Tổng** | | **~$9.30** (Free Tier: **$0.80**) |

### Tối ưu hóa chi phí

```bash
# 1. Sử dụng Reserved Instance (tiết kiệm ~40%)
aws ec2 describe-reserved-instances-offerings \
    --instance-type t2.micro \
    --product-description "Linux/UNIX"

# 2. Schedule start/stop instance
# Tạo Lambda function để tự động stop/start theo lịch

# 3. Monitor usage với CloudWatch
aws logs create-log-group --log-group-name /aws/ec2/odoo

# 4. Setup alerts cho chi phí
aws budgets create-budget \
    --account-id [ACCOUNT_ID] \
    --budget file://budget.json
```

### Scale up khi cần

```bash
# Thay đổi instance type
aws ec2 stop-instances --instance-ids [INSTANCE_ID]
aws ec2 modify-instance-attribute \
    --instance-id [INSTANCE_ID] \
    --instance-type Value=t2.small
aws ec2 start-instances --instance-ids [INSTANCE_ID]
```

## 🔐 Bảo mật

### Recommendations sau khi deploy

1. **Đổi passwords mặc định**:
   ```bash
   # SSH vào server và đổi Odoo admin password
   # Vào Odoo → Settings → Users → Administrator
   ```

2. **Hạn chế SSH access**:
   ```bash
   # Chỉnh Security Group chỉ cho phép SSH từ IP cụ thể
   aws ec2 authorize-security-group-ingress \
       --group-id [SG_ID] \
       --protocol tcp \
       --port 22 \
       --cidr [YOUR_IP]/32
   ```

3. **Enable firewall**:
   ```bash
   sudo ufw enable
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 8069/tcp
   ```

4. **Regular updates**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

## 🔄 Backup và Recovery

### Manual backup

```bash
# 1. Backup database
sudo -u postgres pg_dump odoo18 > odoo18_backup_$(date +%Y%m%d).sql

# 2. Backup file store
sudo tar -czf filestore_backup_$(date +%Y%m%d).tar.gz /opt/odoo/filestore

# 3. Upload to S3 (optional)
aws s3 cp odoo18_backup_$(date +%Y%m%d).sql s3://my-backup-bucket/
aws s3 cp filestore_backup_$(date +%Y%m%d).tar.gz s3://my-backup-bucket/
```

### Setup automated backup (optional)

```bash
# Tạo backup script
cat > /opt/odoo-backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
sudo -u postgres pg_dump odoo18 > /tmp/odoo18_backup_$DATE.sql
aws s3 cp /tmp/odoo18_backup_$DATE.sql s3://my-backup-bucket/
rm /tmp/odoo18_backup_$DATE.sql
EOF

# Set crontab cho daily backup
echo "0 2 * * * /opt/odoo-backup.sh" | sudo crontab -
```

## 🗑️ Xóa Hệ thống

```bash
# Xóa CloudFormation stack (sẽ xóa tất cả resources)
aws cloudformation delete-stack \
    --stack-name odoo-community-18 \
    --region ap-southeast-1

# Verify stack bị xóa
aws cloudformation describe-stacks \
    --stack-name odoo-community-18 \
    --region ap-southeast-1
```

## 🤝 Đóng góp

1. Fork repository
2. Tạo feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Tạo Pull Request

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.

## 🆘 Hỗ trợ

- **Issues**: [GitHub Issues](repository-url/issues)
- **Documentation**: [Odoo Documentation](https://www.odoo.com/documentation/18.0/)
- **AWS Support**: [AWS Documentation](https://docs.aws.amazon.com/)

## 📞 Liên hệ

- **Tác giả**: [Your Name]
- **Email**: [your.email@domain.com]
- **Project Link**: [repository-url]

---

⭐ **Nếu project hữu ích, đừng quên star repository!** ⭐