# 🏢 Odoo Community 18 trên AWS EC2 - Hướng dẫn Triển khai Chi tiết A-Z

![Odoo AWS Banner](https://via.placeholder.com/800x200/875A7B/FFFFFF?text=Odoo+Community+18+on+AWS+EC2)

🎯 **Mục tiêu**: Deploy Odoo Community 18 trên AWS EC2 với chi phí thấp nhất, hoàn toàn tự động hóa từ A đến Z.

📋 **Đối tượng**: Người mới bắt đầu với AWS, muốn deploy Odoo một cách đơn giản và tiết kiệm chi phí.

---

## 📑 Mục lục

- [🎬 Giới thiệu](#-giới-thiệu)
- [💳 BƯỚC 1: Tạo Tài khoản AWS](#-bước-1-tạo-tài-khoản-aws)
- [🔑 BƯỚC 2: Tạo EC2 Key Pair](#-bước-2-tạo-ec2-key-pair)
- [💻 BƯỚC 3: Cài đặt AWS CLI](#-bước-3-cài-đặt-aws-cli)
- [⚙️ BƯỚC 4: Cấu hình AWS Credentials](#-bước-4-cấu-hình-aws-credentials)
- [📁 BƯỚC 5: Download và Setup Dự án](#-bước-5-download-và-setup-dự-án)
- [🚀 BƯỚC 6: Deploy Odoo lên AWS](#-bước-6-deploy-odoo-lên-aws)
- [🌐 BƯỚC 7: Truy cập và Sử dụng Odoo](#-bước-7-truy-cập-và-sử-dụng-odoo)
- [🔧 Quản lý và Troubleshooting](#-quản-lý-và-troubleshooting)
- [💰 Chi phí và Tối ưu hóa](#-chi-phí-và-tối-ưu-hóa)
- [🗑️ Xóa Hệ thống](#️-xóa-hệ-thống)

---

## 🎬 Giới thiệu

### ✨ Tính năng chính

- ✅ **Hoàn toàn tự động**: Chỉ cần 1 lệnh deploy tất cả
- ✅ **Chi phí siêu thấp**: t2.micro (Free Tier) - chỉ $0.80/tháng
- ✅ **Không cần kỹ thuật**: Hướng dẫn từng bước chi tiết
- ✅ **Sẵn sàng dùng**: Database, admin user đã setup sẵn
- ✅ **Bảo mật cơ bản**: Security groups, firewall được cấu hình

### 🏗️ Kiến trúc hệ thống

```
🌐 Internet
      ↓
🛡️  Security Group (Port 22, 80, 8069)
      ↓
💻 EC2 t2.micro (Ubuntu 22.04 LTS)
   ├── 🌐 Nginx (Port 80) → Odoo (Port 8069)
   ├── 🏢 Odoo Community 18
   └── 🗄️  PostgreSQL 14
```

### 💰 Chi phí ước tính

| Tài nguyên | Loại | Chi phí/tháng (USD) |
|------------|------|---------------------|
| EC2 t2.micro | Free Tier | $0 (12 tháng đầu) |
| EC2 t2.micro | Sau Free Tier | $8.50 |
| EBS Storage 8GB | GP2 | $0.80 |
| Data Transfer | Outbound | $0.09/GB |
| **Tổng cộng** | | **$0.80** (Free Tier) / **$9.30** (sau đó) |

---

## 💳 BƯỚC 1: Tạo Tài khoản AWS

### 🛠️ Chuẩn bị trước khi tạo tài khoản

#### 📋 Tài liệu cần thiết:
- ✅ **Thẻ tín dụng/ghi nợ** (Visa, Mastercard, JCB)
- ✅ **Email** (nên dùng email business hoặc cá nhân chính)
- ✅ **Số điện thoại** (để verify)
- ✅ **Địa chỉ** (đầy đủ, đúng với thông tin thẻ)

#### 💡 Lưu ý về thẻ:
- AWS sẽ charge $1 USD để verify thẻ (hoàn lại ngay)
- Nên có ít nhất $5-10 USD trong thẻ để tránh lỗi
- Thẻ ảo (VCB, ACB Virtual) cũng hoạt động tốt

### 📝 Các bước tạo tài khoản AWS

#### Bước 1.1: Truy cập AWS
1. Mở trình duyệt, vào: **https://aws.amazon.com**
2. Click nút **"Create an AWS Account"** (góc trên bên phải)
3. Hoặc vào trực tiếp: **https://portal.aws.amazon.com/billing/signup**

#### Bước 1.2: Điền thông tin tài khoản
1. **Email address**: Nhập email chính của bạn
2. **AWS account name**: Đặt tên tài khoản (VD: "My Business" hoặc "Personal")
3. Click **"Continue"**

#### Bước 1.3: Chọn loại tài khoản
1. Chọn **"Personal"** (cho cá nhân) hoặc **"Business"** (cho công ty)
2. Điền đầy đủ thông tin:
   - **Full name** (Họ tên đầy đủ)
   - **Phone number** (Số điện thoại)
   - **Country/Region**: Chọn **Vietnam**
   - **Address**: Địa chỉ đầy đủ
   - **City**: Thành phố
   - **Postal code**: Mã bưu điện
3. Check ☑️ **"I have read and agree to the terms of the AWS Customer Agreement"**
4. Click **"Continue"**

#### Bước 1.4: Thêm thông tin thanh toán
1. Nhập thông tin thẻ tín dụng:
   - **Card number**: Số thẻ
   - **Expiry date**: MM/YY
   - **Cardholder name**: Tên trên thẻ
   - **CVV/CVC**: Mã bảo mật 3 số
2. **Billing address**:
   - Có thể giống với địa chỉ tài khoản
   - Hoặc điền địa chỉ khác nếu khác
3. Click **"Continue"**

#### Bước 1.5: Xác nhận số điện thoại
1. Chọn **Country code**: **+84** (Vietnam)
2. Nhập **Phone number**: Số điện thoại (bỏ số 0 đầu)
   - VD: 0901234567 → nhập 901234567
3. Chọn method: **"Text message (SMS)"** hoặc **"Voice call"**
4. Click **"Send SMS"** hoặc **"Call me now"**
5. Nhập mã 4 số nhận được từ SMS/cuộc gọi
6. Click **"Continue"**

#### Bước 1.6: Chọn Support Plan
1. Chọn **"Basic Support - Free"**
   - Miễn phí, đủ dùng cho mục đích cá nhân
2. Click **"Complete sign up"**

#### Bước 1.7: Hoàn thành và verify
1. AWS sẽ hiển thị: **"Congratulations! Your AWS account is ready"**
2. Click **"Go to the AWS Management Console"**
3. Nhập email và password để đăng nhập
4. **Chờ 15-30 phút** để tài khoản được fully activate

---

## 🔑 BƯỚC 2: Tạo EC2 Key Pair

EC2 Key Pair là cặp khóa để SSH vào server một cách bảo mật.

### 📍 Cách tạo Key Pair trên AWS Console

#### Bước 2.1: Đăng nhập AWS Console
1. Vào **https://console.aws.amazon.com**
2. Đăng nhập với email/password đã tạo ở Bước 1
3. Chọn **Region** ở góc trên bên phải: **"Asia Pacific (Singapore) ap-southeast-1"**

#### Bước 2.2: Vào EC2 Service
1. Trong AWS Console, tìm kiếm **"EC2"** ở thanh search phía trên
2. Click vào **"EC2"** (Virtual Servers in the Cloud)
3. Hoặc vào trực tiếp: **https://ap-southeast-1.console.aws.amazon.com/ec2**

#### Bước 2.3: Tạo Key Pair
1. Ở sidebar bên trái, tìm section **"Network & Security"**
2. Click **"Key Pairs"**
3. Click nút **"Create key pair"** (màu cam/xanh)

#### Bước 2.4: Cấu hình Key Pair
1. **Name**: Đặt tên key pair (VD: `odoo-key-pair`, `my-aws-key`)
2. **Key pair type**: Chọn **"RSA"** (recommended)
3. **Private key file format**:
   - **Windows**: Chọn **".ppk"** (cho PuTTY)
   - **Mac/Linux**: Chọn **".pem"** (cho SSH)
4. **Tags** (optional): Có thể bỏ trống
5. Click **"Create key pair"**

#### Bước 2.5: Download và lưu Key
1. File key sẽ tự động download về máy
2. **LƯU GIỮ FILE NÀY CẨN THẬN!**
   - Nếu mất file này, không thể SSH vào server
   - AWS không thể tái tạo lại file này
3. Di chuyển file đến nơi an toàn:
   - **Windows**: `C:\Users\[Username]\.ssh\`
   - **Mac/Linux**: `~/.ssh/`
4. **Chmod file** (Mac/Linux only):
   ```bash
   chmod 600 ~/.ssh/odoo-key-pair.pem
   ```

#### 🔍 Xác nhận Key Pair đã tạo thành công
1. Quay lại **EC2 → Key Pairs**
2. Bạn sẽ thấy key pair vừa tạo trong danh sách
3. **Ghi nhớ tên key pair** để dùng ở bước deploy

---

## 💻 BƯỚC 3: Cài đặt AWS CLI

AWS CLI giúp bạn điều khiển AWS từ command line.

### 🪟 Windows

#### Cách 1: Download Installer (Dễ nhất)
1. Vào: **https://awscli.amazonaws.com/AWSCLIV2.msi**
2. Download file MSI và chạy
3. Follow setup wizard (Next → Next → Install)
4. Mở **Command Prompt** hoặc **PowerShell**
5. Verify: `aws --version`

#### Cách 2: Qua PowerShell (Admin)
```powershell
# Mở PowerShell as Administrator
Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "AWSCLIV2.msi"
Start-Process msiexec.exe -ArgumentList '/i AWSCLIV2.msi /quiet' -Wait
```

### 🍎 macOS

#### Cách 1: Homebrew (Recommended)
```bash
# Cài Homebrew (nếu chưa có)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Cài AWS CLI
brew install awscli

# Verify
aws --version
```

#### Cách 2: Download Installer
1. Download: **https://awscli.amazonaws.com/AWSCLIV2.pkg**
2. Double-click file PKG và follow hướng dẫn

### 🐧 Linux (Ubuntu/Debian)

#### Cách 1: Snap (Ubuntu)
```bash
sudo snap install aws-cli --classic
aws --version
```

#### Cách 2: APT
```bash
sudo apt update
sudo apt install awscli -y
aws --version
```

#### Cách 3: Download Official (All Linux)
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

### ✅ Verify Installation
Chạy lệnh sau để kiểm tra:
```bash
aws --version
```
Kết quả mong đợi:
```
aws-cli/2.x.x Python/3.x.x Linux/5.x.x source/x86_64.x86_64
```

---

## ⚙️ BƯỚC 4: Cấu hình AWS Credentials

### 🔐 Tạo Access Keys trên AWS Console

#### Bước 4.1: Vào IAM Service
1. Đăng nhập **AWS Console**
2. Search **"IAM"** → Click **"IAM"**
3. Hoặc vào: **https://console.aws.amazon.com/iam**

#### Bước 4.2: Tạo Access Key
1. Sidebar bên trái → Click **"Users"**
2. Click **"Create user"** (nếu chưa có user)
3. Hoặc click username hiện tại
4. Tab **"Security credentials"**
5. Section **"Access keys"** → Click **"Create access key"**

#### Bước 4.3: Chọn Use Case
1. Chọn **"Command Line Interface (CLI)"**
2. Check ☑️ **"I understand the above recommendation..."**
3. Click **"Next"**

#### Bước 4.4: Tạo và Download
1. **Description tag** (optional): "Odoo AWS CLI Access"
2. Click **"Create access key"**
3. **QUAN TRỌNG**: Copy hoặc download credentials:
   - **Access Key ID**: AKIA...
   - **Secret Access Key**: wJalrXUt...
4. Click **"Download .csv file"** để backup
5. Click **"Done"**

### 🔧 Cấu hình AWS CLI

#### Cách 1: Interactive Setup (Recommended)
```bash
aws configure
```

Nhập thông tin như sau:
```
AWS Access Key ID [None]: AKIA... (paste Access Key ID)
AWS Secret Access Key [None]: wJalr... (paste Secret Access Key)
Default region name [None]: ap-southeast-1
Default output format [None]: json
```

#### Cách 2: Environment Variables
```bash
# Windows Command Prompt
set AWS_ACCESS_KEY_ID=AKIA...
set AWS_SECRET_ACCESS_KEY=wJalr...
set AWS_DEFAULT_REGION=ap-southeast-1

# Windows PowerShell
$env:AWS_ACCESS_KEY_ID="AKIA..."
$env:AWS_SECRET_ACCESS_KEY="wJalr..."
$env:AWS_DEFAULT_REGION="ap-southeast-1"

# Mac/Linux
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=wJalr...
export AWS_DEFAULT_REGION=ap-southeast-1
```

### ✅ Test Cấu hình
```bash
aws sts get-caller-identity
```

Kết quả mong đợi:
```json
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

---

## 📁 BƯỚC 5: Download và Setup Dự án

### 💾 Download source code

#### Cách 1: Git Clone (Nếu có Git)
```bash
# Clone repository
git clone https://github.com/your-username/odoo-aws-deployment.git
cd odoo-aws-deployment
```

#### Cách 2: Download ZIP
1. Vào GitHub repository page
2. Click **"Code"** → **"Download ZIP"**
3. Extract ZIP file
4. Mở Command Prompt/Terminal ở thư mục đã extract

#### Cách 3: Copy Files Manual
Nếu không có internet tốt, bạn có thể tạo từng file theo hướng dẫn dưới.

### 📂 Cấu trúc thư mục dự án

```
odoo-aws-deployment/
├── 📁 cloudformation/
│   └── 📄 odoo-simple.yaml        # CloudFormation template
├── 📁 scripts/
│   ├── 📄 user-data.sh           # Script cài đặt Odoo
│   ├── 📄 health-check.sh        # Health monitoring
│   ├── 📄 test-template.sh       # Test template
│   └── 📄 cleanup.sh             # Cleanup resources
├── 📁 configs/
│   ├── 📄 odoo.conf              # Odoo config
│   ├── 📄 nginx-simple.conf      # Nginx config
│   └── 📄 odoo.service           # Systemd service
├── 📄 deploy.sh                   # Main deploy script
├── 📄 README.md                   # Hướng dẫn này
└── 📄 .gitignore                  # Git ignore file
```

### 🔧 Setup quyền thực thi (Mac/Linux)

```bash
# Cấp quyền execute cho scripts
chmod +x deploy.sh
chmod +x scripts/*.sh

# Verify
ls -la *.sh scripts/*.sh
```

### 🧪 Test template trước khi deploy

```bash
# Validate CloudFormation template
./scripts/test-template.sh
```

Kết quả mong đợi:
```
==========================================
🧪 TEST CLOUDFORMATION TEMPLATE
==========================================
✅ AWS CLI và credentials OK
✅ Template syntax hợp lệ
✅ AMI ami-0fa377108253bf620 tồn tại trong region ap-southeast-1
✅ Tất cả tests đã pass!
```

---

## 🚀 BƯỚC 6: Deploy Odoo lên AWS

### 🎯 Deploy với settings mặc định (Đơn giản nhất)

```bash
# Deploy ngay lập tức
./deploy.sh
```

### 🎛️ Deploy với tùy chọn

#### Deploy với SSH Key (Recommended)
```bash
# Sử dụng key pair đã tạo ở Bước 2
./deploy.sh -k odoo-key-pair
```

#### Deploy với instance type lớn hơn
```bash
# Nếu muốn performance tốt hơn
./deploy.sh -t t2.small -k odoo-key-pair
```

#### Deploy với custom tên stack
```bash
# Đặt tên stack khác với mặc định
./deploy.sh -n my-company-odoo -k odoo-key-pair
```

#### Deploy đầy đủ options
```bash
./deploy.sh -n my-odoo -t t2.small -k odoo-key-pair -r ap-southeast-1
```

### 📋 Các tùy chọn deploy

| Tham số | Mô tả | Mặc định | Ví dụ |
|---------|-------|----------|-------|
| `-n, --name` | Tên CloudFormation stack | `odoo-community-18` | `-n my-odoo` |
| `-r, --region` | AWS region | `ap-southeast-1` | `-r us-east-1` |
| `-t, --type` | EC2 instance type | `t2.micro` | `-t t2.small` |
| `-k, --key` | EC2 Key Pair name | Không dùng | `-k my-key` |

### 📊 Theo dõi quá trình deploy

#### Trong Terminal
Deploy script sẽ hiển thị progress real-time:
```
==========================================
🚀 DEPLOY ODOO COMMUNITY 18 LÊN AWS
==========================================
📋 Thông tin deployment:
Stack Name: odoo-community-18
Region: ap-southeast-1
Instance Type: t2.micro
Key Pair: odoo-key-pair

🔍 Kiểm tra CloudFormation template...
✅ Template hợp lệ
🚀 Bắt đầu deploy CloudFormation stack...
✅ CloudFormation stack được tạo thành công
⏳ Đang chờ stack deploy hoàn thành...
   Thời gian ước tính: 5-10 phút
```

#### Trên AWS Console (Optional)
1. Vào **AWS Console** → **CloudFormation**
2. Tìm stack **"odoo-community-18"**
3. Tab **"Events"** để xem chi tiết progress
4. Tab **"Resources"** để xem resources đang được tạo

### ⏱️ Thời gian deploy

- **CloudFormation Stack**: 2-3 phút
- **EC2 Instance Launch**: 1-2 phút
- **Odoo Installation**: 3-5 phút
- **Total**: 6-10 phút

### ✅ Deploy thành công

Khi hoàn thành, bạn sẽ thấy:
```
🎉 Deploy thành công!

📊 Thông tin hệ thống:
+----------------+------------------------+
|    OutputKey   |     OutputValue        |
+----------------+------------------------+
| InstancePublicIP | 52.77.123.456        |
| OdooURL        | http://52.77.123.456:8069 |
| DatabaseName   | odoo18                 |
| AdminUser      | admin                  |
| AdminPassword  | admin123               |
+----------------+------------------------+

========================================
🎯 THÔNG TIN TRUY CẬP ODOO
========================================
🌐 URL Odoo:     http://52.77.123.456:8069
🌐 URL Nginx:    http://52.77.123.456
🗃️  Database:    odoo18
👤 Admin User:   admin
🔐 Admin Pass:   admin123
🔧 SSH Command:  ssh ubuntu@52.77.123.456
========================================
```

---

## 🌐 BƯỚC 7: Truy cập và Sử dụng Odoo

### 🔗 Truy cập Odoo Web Interface

#### Bước 7.1: Mở trình duyệt
1. Copy URL từ kết quả deploy: `http://[IP]:8069`
2. Dán vào trình duyệt (Chrome, Firefox, Safari, Edge)
3. **Đợi 2-3 phút** để Odoo khởi động hoàn toàn

#### Bước 7.2: Trang đăng nhập Odoo
1. Bạn sẽ thấy trang login của Odoo Community 18
2. Nếu thấy "Database selector", chọn **"odoo18"**
3. Nếu không load được, đợi thêm vài phút

#### Bước 7.3: Đăng nhập
```
👤 Email: admin
🔐 Password: admin123
```

#### Bước 7.4: Setup ban đầu
1. **Welcome Screen**: Click **"Create a new database"** nếu cần
2. **Company Information**:
   - Company Name: Tên công ty của bạn
   - Currency: VND (Vietnam Dong) hoặc USD
   - Country: Vietnam
3. **Apps Selection**: Chọn apps bạn cần:
   - **Sales**: Quản lý bán hàng
   - **CRM**: Quản lý khách hàng
   - **Inventory**: Quản lý kho
   - **Accounting**: Kế toán
   - **Project**: Quản lý dự án
4. Click **"Create"** và đợi setup hoàn thành

### 🧪 Test các chức năng cơ bản

#### Test 1: Tạo Customer mới
1. **Apps** → **CRM** hoặc **Sales**
2. **Customers** → **Create**
3. Điền thông tin khách hàng test
4. **Save** → Verify dữ liệu đã lưu

#### Test 2: Tạo Product
1. **Apps** → **Sales** hoặc **Inventory**
2. **Products** → **Create**
3. Tạo sản phẩm test với giá
4. **Save** và kiểm tra

#### Test 3: Tạo Sales Order
1. **Sales** → **Orders** → **Create**
2. Chọn customer và product vừa tạo
3. **Confirm** order
4. Kiểm tra workflow chạy đúng

### 📱 Truy cập từ Mobile

Odoo có responsive design, hoạt động tốt trên mobile:
- **iOS Safari**: Mở URL, có thể "Add to Home Screen"
- **Android Chrome**: Tương tự, có thể tạo PWA
- **Mobile Apps**: Download "Odoo" từ App Store/Play Store

### 🔒 Bảo mật sau khi setup

#### Đổi Admin Password
1. **Settings** → **Users & Companies** → **Users**
2. Click user **"Administrator"**
3. Tab **"Account Security"** → **Change Password**
4. Đặt password mạnh mới

#### Tạo Users mới
1. **Settings** → **Users & Companies** → **Users**
2. **Create** → Điền thông tin
3. Chọn **Access Rights** phù hợp
4. **Save** và send invitation

#### Enable Two-Factor Authentication
1. **Settings** → **Users & Companies** → **Users**
2. Edit user → Tab **"Account Security"**
3. **Enable Two-Factor Authentication**
4. Scan QR code với Google Authenticator

---

## 🔧 Quản lý và Troubleshooting

### 🔍 Kiểm tra trạng thái hệ thống

#### SSH vào server (nếu có key pair)
```bash
# Lấy IP từ AWS outputs
aws cloudformation describe-stacks \
    --stack-name odoo-community-18 \
    --query 'Stacks[0].Outputs[?OutputKey==`InstancePublicIP`].OutputValue' \
    --output text

# SSH vào server
ssh ubuntu@[IP_ADDRESS] -i ~/.ssh/odoo-key-pair.pem

# Hoặc Windows với PuTTY:
# Host: ubuntu@[IP_ADDRESS]
# Port: 22
# Auth: Load odoo-key-pair.ppk
```

#### Chạy Health Check
```bash
# Trên server, chạy health check
sudo /home/ubuntu/health-check.sh

# Hoặc download và chạy
curl -o health-check.sh https://raw.githubusercontent.com/[repo]/main/scripts/health-check.sh
chmod +x health-check.sh
sudo ./health-check.sh
```

Kết quả mong đợi:
```
==========================================
🏥 ODOO HEALTH CHECK
==========================================
✅ PostgreSQL: RUNNING
✅ Nginx: RUNNING
✅ Odoo: RUNNING
✅ Port 5432 (PostgreSQL): LISTENING
✅ Port 80 (Nginx): LISTENING
✅ Port 8069 (Odoo): LISTENING
✅ HTTP Nginx: OK
✅ HTTP Odoo: OK
✅ Database 'odoo18': ACCESSIBLE
✅ Active Users: 1

🎉 System Status: EXCELLENT (10/10 checks passed)
```

### 🔧 Quản lý Services

#### Odoo Service
```bash
# Xem status
sudo systemctl status odoo

# Start/Stop/Restart
sudo systemctl start odoo
sudo systemctl stop odoo
sudo systemctl restart odoo

# Xem logs real-time
sudo tail -f /var/log/odoo/odoo.log

# Xem logs systemd
sudo journalctl -u odoo -f
```

#### Nginx Service
```bash
# Status và restart
sudo systemctl status nginx
sudo systemctl restart nginx

# Test config
sudo nginx -t

# Logs
sudo tail -f /var/log/nginx/odoo.access.log
sudo tail -f /var/log/nginx/odoo.error.log
```

#### PostgreSQL Service
```bash
# Status và restart
sudo systemctl status postgresql
sudo systemctl restart postgresql

# Connect database
sudo -u postgres psql -d odoo18

# List databases
sudo -u postgres psql -c "\l"

# List users
sudo -u postgres psql -c "\du"
```

### 🚨 Troubleshooting Common Issues

#### ❌ Không truy cập được Odoo (HTTP timeout)

**Nguyên nhân**: Security Group chưa mở port 8069

**Giải pháp**:
```bash
# Lấy Security Group ID
aws cloudformation describe-stack-resources \
    --stack-name odoo-community-18 \
    --query 'StackResources[?ResourceType==`AWS::EC2::SecurityGroup`].PhysicalResourceId' \
    --output text

# Kiểm tra rules hiện tại
aws ec2 describe-security-groups --group-ids [SG-ID]

# Nếu thiếu port 8069, thêm rule:
aws ec2 authorize-security-group-ingress \
    --group-id [SG-ID] \
    --protocol tcp \
    --port 8069 \
    --cidr 0.0.0.0/0
```

#### ❌ Odoo Service không start được

**Check logs**:
```bash
sudo journalctl -u odoo --no-pager -l
sudo tail -50 /var/log/odoo/odoo.log
```

**Common fixes**:
```bash
# Fix permissions
sudo chown -R odoo:odoo /opt/odoo
sudo chown odoo:odoo /var/log/odoo/odoo.log

# Reset config
sudo cp /home/ubuntu/configs/odoo.conf /etc/odoo.conf
sudo chown odoo:odoo /etc/odoo.conf

# Restart
sudo systemctl restart odoo
```

#### ❌ Database connection error

**Check PostgreSQL**:
```bash
# Test connection
sudo -u postgres psql -c "SELECT version();"

# Recreate database if needed
sudo -u postgres dropdb odoo18
sudo -u postgres createdb -O odoo odoo18
```

**Reset database password**:
```bash
sudo -u postgres psql -c "ALTER USER odoo WITH PASSWORD 'odoo123';"
```

#### ❌ Nginx 502 Bad Gateway

**Causes**: Odoo service down or wrong upstream config

**Fix**:
```bash
# Check if Odoo is running on port 8069
sudo netstat -tlnp | grep 8069

# If not, start Odoo
sudo systemctl start odoo

# Test Nginx config
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

#### ❌ Out of Memory (t2.micro has only 1GB RAM)

**Symptoms**: Services crash randomly, slow response

**Solutions**:
1. **Add swap file**:
   ```bash
   sudo fallocate -l 1G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   ```

2. **Upgrade instance type**:
   ```bash
   # Stop instance
   aws ec2 stop-instances --instance-ids [INSTANCE-ID]

   # Change to t2.small (2GB RAM)
   aws ec2 modify-instance-attribute \
       --instance-id [INSTANCE-ID] \
       --instance-type Value=t2.small

   # Start instance
   aws ec2 start-instances --instance-ids [INSTANCE-ID]
   ```

### 📊 Monitoring và Performance

#### System Resources
```bash
# CPU, Memory usage
htop
# or
top

# Disk usage
df -h
du -sh /opt/odoo
du -sh /var/log

# Network connections
sudo netstat -tulnp | grep -E "(80|8069|5432)"
```

#### Odoo Performance
```bash
# Check active connections
sudo -u postgres psql -d odoo18 -c "SELECT count(*) FROM pg_stat_activity;"

# Database size
sudo -u postgres psql -d odoo18 -c "SELECT pg_size_pretty(pg_database_size('odoo18'));"

# Slow queries (if enabled)
sudo -u postgres psql -d odoo18 -c "SELECT query, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
```

---

## 💰 Chi phí và Tối ưu hóa

### 💸 Chi phí chi tiết (Region ap-southeast-1)

#### Free Tier (12 tháng đầu)
| Resource | Limit Free Tier | Chi phí |
|----------|----------------|---------|
| EC2 t2.micro | 750 giờ/tháng | $0 |
| EBS Storage | 30GB | $0 |
| Data Transfer Out | 15GB/tháng | $0 |
| **Tổng** | | **$0** |

#### Sau Free Tier
| Resource | Usage | Đơn giá | Chi phí/tháng |
|----------|-------|---------|---------------|
| EC2 t2.micro | 24/7 (730h) | $0.0116/h | $8.47 |
| EBS GP2 8GB | 8GB | $0.10/GB | $0.80 |
| Data Transfer Out | 10GB | $0.09/GB | $0.90 |
| **Tổng** | | | **~$10.17** |

#### So sánh Instance Types
| Instance | vCPU | RAM | Chi phí/tháng | Phù hợp cho |
|----------|------|-----|---------------|-------------|
| t2.micro | 1 | 1GB | $8.47 | Demo, test, <5 users |
| t2.small | 1 | 2GB | $16.94 | Sản xuất nhỏ, <10 users |
| t2.medium | 2 | 4GB | $33.87 | Sản xuất vừa, <25 users |
| t3.small | 2 | 2GB | $18.98 | Performance tốt hơn t2 |

### 📉 Các cách tiết kiệm chi phí

#### 1. Sử dụng Reserved Instances (tiết kiệm ~40%)
```bash
# Tìm Reserved Instance offerings
aws ec2 describe-reserved-instances-offerings \
    --instance-type t2.micro \
    --product-description "Linux/UNIX" \
    --region ap-southeast-1

# Purchase 1-year term (ví dụ)
aws ec2 purchase-reserved-instances-offering \
    --reserved-instances-offering-id [OFFERING-ID] \
    --instance-count 1
```

#### 2. Schedule Start/Stop Instance
Tạo Lambda function để tự động tắt/mở theo lịch:

**Lambda function code** (Python):
```python
import boto3
import json

def lambda_handler(event, context):
    ec2 = boto3.client('ec2', region_name='ap-southeast-1')

    # Replace with your instance ID
    instance_id = 'i-1234567890abcdef0'

    if event['action'] == 'stop':
        ec2.stop_instances(InstanceIds=[instance_id])
        return {'statusCode': 200, 'body': 'Instance stopped'}
    elif event['action'] == 'start':
        ec2.start_instances(InstanceIds=[instance_id])
        return {'statusCode': 200, 'body': 'Instance started'}
```

**CloudWatch Events Rules**:
- Stop: `cron(0 18 * * ? *)` (6PM daily)
- Start: `cron(0 8 * * ? *)` (8AM daily)

#### 3. Monitor và Alert Chi phí
```bash
# Tạo budget alert
aws budgets create-budget \
    --account-id [ACCOUNT-ID] \
    --budget '{
        "BudgetName": "Odoo-Monthly-Budget",
        "BudgetLimit": {"Amount": "15", "Unit": "USD"},
        "TimeUnit": "MONTHLY",
        "BudgetType": "COST"
    }' \
    --notifications-with-subscribers '[{
        "Notification": {
            "NotificationType": "ACTUAL",
            "ComparisonOperator": "GREATER_THAN",
            "Threshold": 80
        },
        "Subscribers": [{
            "SubscriptionType": "EMAIL",
            "Address": "your-email@example.com"
        }]
    }]'
```

#### 4. Optimize Storage
```bash
# Check disk usage
df -h

# Clean old logs (nếu cần)
sudo find /var/log -name "*.log" -type f -mtime +30 -delete

# Clean old Odoo logs
sudo find /var/log/odoo -name "*.log.*" -type f -mtime +7 -delete

# Setup log rotation
sudo nano /etc/logrotate.d/odoo
```

#### 5. Database Optimization
```bash
# Vacuum PostgreSQL database
sudo -u postgres psql -d odoo18 -c "VACUUM FULL;"

# Reindex database
sudo -u postgres psql -d odoo18 -c "REINDEX DATABASE odoo18;"

# Analyze query performance
sudo -u postgres psql -d odoo18 -c "SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"
```

### 📊 Cost Monitoring Tools

#### 1. AWS Cost Explorer
1. **AWS Console** → **Billing and Cost Management** → **Cost Explorer**
2. Set up **Daily/Monthly** reports
3. Create **Cost Anomaly Detection**

#### 2. AWS CLI Cost Commands
```bash
# Current month cost
aws ce get-cost-and-usage \
    --time-period Start=2024-01-01,End=2024-02-01 \
    --granularity MONTHLY \
    --metrics BlendedCost

# Daily costs last 7 days
aws ce get-cost-and-usage \
    --time-period Start=2024-01-15,End=2024-01-22 \
    --granularity DAILY \
    --metrics UnblendedCost
```

#### 3. Third-party Tools
- **CloudWatch Dashboards**: Free monitoring
- **AWS Trusted Advisor**: Cost optimization recommendations
- **CloudHealth**: Advanced cost management (paid)

---

## 🗑️ Xóa Hệ thống

### 🚨 Backup trước khi xóa

#### Backup Database
```bash
# SSH vào server
ssh ubuntu@[IP] -i ~/.ssh/odoo-key-pair.pem

# Backup database
sudo -u postgres pg_dump odoo18 > odoo18_backup_$(date +%Y%m%d).sql

# Download về máy local (từ máy local)
scp -i ~/.ssh/odoo-key-pair.pem ubuntu@[IP]:~/odoo18_backup_*.sql ./
```

#### Backup Files (optional)
```bash
# Backup filestore and configs
sudo tar -czf odoo_files_backup_$(date +%Y%m%d).tar.gz \
    /opt/odoo/filestore \
    /etc/odoo.conf \
    /var/log/odoo

# Download
scp -i ~/.ssh/odoo-key-pair.pem ubuntu@[IP]:~/odoo_files_backup_*.tar.gz ./
```

### 🗑️ Xóa Stack bằng Script

#### Cách 1: Dùng cleanup script
```bash
# Xóa stack mặc định
./scripts/cleanup.sh -n odoo-community-18

# Với force (không hỏi xác nhận)
./scripts/cleanup.sh -n odoo-community-18 -f
```

#### Cách 2: AWS CLI trực tiếp
```bash
# Liệt kê stacks để xác nhận tên
aws cloudformation list-stacks \
    --stack-status-filter CREATE_COMPLETE \
    --query 'StackSummaries[*].{Name:StackName,Status:StackStatus}'

# Xóa stack
aws cloudformation delete-stack \
    --stack-name odoo-community-18 \
    --region ap-southeast-1

# Monitor deletion progress
aws cloudformation describe-stack-events \
    --stack-name odoo-community-18 \
    --region ap-southeast-1
```

### 🖥️ Xóa qua AWS Console

#### Bước 1: Vào CloudFormation
1. **AWS Console** → **CloudFormation**
2. Tìm stack **"odoo-community-18"**

#### Bước 2: Delete Stack
1. Chọn stack → **Actions** → **Delete stack**
2. Confirm deletion
3. Monitor trong **Events** tab

#### Bước 3: Verify Deletion
Đợi 5-10 phút và verify:
- **EC2 Instances**: Terminated
- **Security Groups**: Deleted
- **EBS Volumes**: Deleted (nếu DeleteOnTermination=true)

### 🔍 Kiểm tra Resources còn sót

#### Check Orphaned Resources
```bash
# EC2 Instances
aws ec2 describe-instances \
    --filters "Name=tag:aws:cloudformation:stack-name,Values=odoo-community-18" \
    --query 'Reservations[*].Instances[?State.Name!=`terminated`].[InstanceId,State.Name]'

# Security Groups
aws ec2 describe-security-groups \
    --filters "Name=tag:aws:cloudformation:stack-name,Values=odoo-community-18" \
    --query 'SecurityGroups[*].[GroupId,GroupName]'

# EBS Volumes
aws ec2 describe-volumes \
    --filters "Name=tag:aws:cloudformation:stack-name,Values=odoo-community-18" \
    --query 'Volumes[?State!=`deleted`].[VolumeId,State]'
```

#### Manual Cleanup (nếu cần)
```bash
# Force terminate instance
aws ec2 terminate-instances --instance-ids [INSTANCE-ID]

# Delete security group (sau khi instance terminated)
aws ec2 delete-security-group --group-id [SG-ID]

# Delete EBS volume (nếu không auto-delete)
aws ec2 delete-volume --volume-id [VOLUME-ID]
```

### 💡 Tips cho Cleanup

#### 1. Grace Period
- **EC2**: Có thể mất 1-2 phút để terminate
- **EBS**: Auto-delete nếu DeleteOnTermination=true
- **Security Groups**: Chỉ xóa được sau khi instance terminated

#### 2. Billing Impact
- **Stopped instances**: Vẫn tính phí EBS storage
- **Terminated instances**: Stop charging ngay lập tức
- **Data transfer**: Có thể vẫn charge vài giờ sau terminate

#### 3. Key Pair Cleanup
```bash
# List key pairs
aws ec2 describe-key-pairs

# Delete key pair (optional)
aws ec2 delete-key-pair --key-name odoo-key-pair

# Delete local key file
rm ~/.ssh/odoo-key-pair.pem
```

---

## 🤝 Hỗ trợ và Liên hệ

### 📞 Khi cần hỗ trợ

#### 1. Check Common Issues trước
- Đọc lại section **"🚨 Troubleshooting Common Issues"**
- Chạy **health-check.sh** để diagnosis
- Check AWS Console logs

#### 2. Thu thập thông tin
Khi báo lỗi, cung cấp:
```bash
# System info
aws --version
aws sts get-caller-identity

# Stack info
aws cloudformation describe-stacks --stack-name odoo-community-18

# Instance info (nếu có)
aws ec2 describe-instances --instance-ids [INSTANCE-ID]

# Logs (nếu có SSH access)
sudo tail -50 /var/log/odoo/odoo.log
sudo systemctl status odoo
```

#### 3. Tạo GitHub Issue
**Format báo lỗi**:
```
### Environment
- OS: Windows/Mac/Linux
- AWS CLI Version:
- Region: ap-southeast-1
- Instance Type: t2.micro

### Problem Description
[Mô tả chi tiết vấn đề]

### Steps to Reproduce
1.
2.
3.

### Expected vs Actual Result
Expected:
Actual:

### Logs/Screenshots
[Paste logs hoặc attach screenshots]

### Additional Context
[Thông tin thêm nếu có]
```

### 🔗 Useful Links

#### Documentation
- **📖 Odoo Documentation**: https://www.odoo.com/documentation/18.0/
- **📚 AWS EC2 Docs**: https://docs.aws.amazon.com/ec2/
- **☁️ CloudFormation Guide**: https://docs.aws.amazon.com/cloudformation/
- **💻 AWS CLI Reference**: https://docs.aws.amazon.com/cli/

#### Community Support
- **🗨️ Odoo Community Forum**: https://www.odoo.com/forum/
- **💬 AWS Forums**: https://forums.aws.amazon.com/
- **📱 Stack Overflow**: Tag `odoo`, `aws-ec2`, `cloudformation`

#### Official Support
- **🎫 AWS Support**: https://console.aws.amazon.com/support/ (nếu có support plan)
- **📧 Odoo Enterprise Support**: Chỉ cho Odoo Enterprise edition

### 🎓 Learning Resources

#### AWS Learning
- **🆓 AWS Free Training**: https://aws.amazon.com/training/free/
- **📹 AWS YouTube Channel**: https://youtube.com/user/AmazonWebServices
- **📖 AWS Well-Architected**: https://aws.amazon.com/architecture/well-architected/

#### Odoo Learning
- **📚 Odoo eLearning**: https://www.odoo.com/slides
- **🎥 Odoo YouTube**: https://youtube.com/user/OpenERPonline
- **📖 Odoo Books**: https://www.odoo.com/page/odoo-book

#### DevOps & Cloud
- **📘 Infrastructure as Code**: Terraform, CloudFormation guides
- **🔧 Linux System Administration**: Ubuntu server management
- **🐳 Container Learning**: Docker, để có thể containerize Odoo sau này

---

## 📋 Appendices

### 📝 A. Troubleshooting Checklist

**Khi Odoo không accessible:**

- [ ] ✅ Instance đang running? (`aws ec2 describe-instances`)
- [ ] ✅ Security Group có port 8069 open?
- [ ] ✅ Odoo service đang running? (`systemctl status odoo`)
- [ ] ✅ PostgreSQL running? (`systemctl status postgresql`)
- [ ] ✅ Port 8069 listening? (`netstat -tlnp | grep 8069`)
- [ ] ✅ Firewall không block? (`sudo ufw status`)
- [ ] ✅ Đợi đủ thời gian startup? (3-5 phút sau deploy)

**Khi SSH không connect được:**

- [ ] ✅ Key pair đúng file và permission? (`chmod 600 key.pem`)
- [ ] ✅ Security Group có port 22?
- [ ] ✅ Instance có Public IP?
- [ ] ✅ Username đúng? (Ubuntu instance dùng `ubuntu@`)
- [ ] ✅ SSH command syntax đúng? (`ssh ubuntu@IP -i key.pem`)

### 📊 B. Performance Tuning

#### Odoo Configuration Optimization
```ini
# /etc/odoo.conf - Production settings
[options]
# Worker processes (multiprocessing)
workers = 2  # For t2.small: 2-4, t2.micro: 0 (single-process)
max_cron_threads = 1

# Memory management
limit_memory_hard = 671088640  # 640MB for t2.micro
limit_memory_soft = 629145600  # 600MB
limit_request = 8192

# Database connections
db_maxconn = 64

# Timeouts
limit_time_cpu = 60
limit_time_real = 120

# Logging
log_level = warn  # Less verbose in production
logrotate = True
```

#### PostgreSQL Tuning (cho t2.micro)
```bash
# Edit PostgreSQL config
sudo nano /etc/postgresql/14/main/postgresql.conf

# Add these settings:
shared_buffers = 128MB
effective_cache_size = 512MB
work_mem = 4MB
maintenance_work_mem = 64MB
max_connections = 40
```

#### Nginx Caching
```nginx
# /etc/nginx/sites-available/odoo
http {
    # Enable gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;

    # Proxy caching
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=odoo_cache:10m max_size=100m inactive=60m;

    server {
        # Static files caching
        location ~* /web/static/ {
            proxy_cache odoo_cache;
            proxy_cache_valid 200 1h;
            expires 1d;
            add_header X-Cache-Status $upstream_cache_status;
            proxy_pass http://odoo;
        }
    }
}
```

### 🔐 C. Security Hardening

#### SSH Security
```bash
# Disable password auth, only key-based
sudo nano /etc/ssh/sshd_config

# Change these:
PasswordAuthentication no
PermitRootLogin no
Port 2222  # Change default port

sudo systemctl restart ssh
```

#### UFW Firewall
```bash
# Enable UFW
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow only required ports
sudo ufw allow 2222/tcp   # SSH (custom port)
sudo ufw allow 80/tcp     # HTTP
sudo ufw allow 443/tcp    # HTTPS (future)
sudo ufw allow 8069/tcp   # Odoo

# Enable firewall
sudo ufw --force enable
sudo ufw status verbose
```

#### Fail2Ban (SSH Protection)
```bash
# Install fail2ban
sudo apt update
sudo apt install fail2ban -y

# Configure
sudo nano /etc/fail2ban/jail.local

[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log

sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

#### Database Security
```bash
# Change PostgreSQL passwords
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'new-strong-password';"
sudo -u postgres psql -c "ALTER USER odoo WITH PASSWORD 'new-odoo-password';"

# Update Odoo config
sudo nano /etc/odoo.conf
# Change: db_password = new-odoo-password

sudo systemctl restart odoo
```

### 📈 D. Monitoring Setup

#### CloudWatch Agent
```bash
# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo dpkg -i amazon-cloudwatch-agent.rpm

# Configure
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard

# Start agent
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent
```

#### Log Monitoring
```bash
# Ship logs to CloudWatch
aws logs create-log-group --log-group-name /aws/ec2/odoo

# Install awslogs
sudo apt install awscli -y
pip3 install awscli-cwlogs

# Configure log shipping
sudo nano /etc/awslogs/awslogs.conf
```

#### Custom Health Check
```bash
# Create monitoring script
sudo nano /opt/monitor-odoo.sh

#!/bin/bash
# Check Odoo health and send to CloudWatch
NAMESPACE="Custom/Odoo"
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Check if Odoo responds
if curl -f -s http://localhost:8069/web/health > /dev/null; then
    aws cloudwatch put-metric-data --namespace $NAMESPACE --metric-data MetricName=OdooHealth,Value=1,Unit=Count
else
    aws cloudwatch put-metric-data --namespace $NAMESPACE --metric-data MetricName=OdooHealth,Value=0,Unit=Count
fi

# Add to crontab
echo "*/5 * * * * /opt/monitor-odoo.sh" | sudo crontab -
```

---

## 🎉 Kết luận

Chúc mừng! 🎊 Bạn đã hoàn thành việc deploy **Odoo Community 18** trên **AWS EC2** từ A đến Z!

### ✅ Những gì bạn đã đạt được:

1. **💳 Tạo tài khoản AWS** với Free Tier
2. **🔑 Tạo EC2 Key Pair** để SSH bảo mật
3. **💻 Setup AWS CLI** và credentials
4. **🚀 Deploy Odoo** hoàn toàn tự động bằng CloudFormation
5. **🌐 Truy cập và sử dụng** Odoo qua web browser
6. **🔧 Học cách quản lý** và troubleshoot hệ thống
7. **💰 Hiểu rõ chi phí** và cách tối ưu hóa
8. **🗑️ Biết cách cleanup** resources để tránh waste money

### 🎯 Next Steps:

#### Ngắn hạn (1-2 tuần):
- 📚 **Học Odoo**: Explore các modules (Sales, CRM, Inventory, Accounting)
- 🔒 **Tăng cường bảo mật**: Đổi passwords, setup 2FA
- 📊 **Monitor chi phí**: Setup billing alerts
- 🔄 **Backup thường xuyên**: Database và filestore

#### Trung hạn (1-3 tháng):
- 🌐 **Custom domain**: Mua domain và setup DNS
- 🔐 **SSL Certificate**: Let's Encrypt hoặc AWS Certificate Manager
- 📈 **Scale up**: Upgrade instance type nếu cần
- 🏢 **Company setup**: Customize Odoo theo business của bạn

#### Dài hạn (3-6 tháng):
- 🐳 **Containerization**: Migrate sang Docker/Kubernetes
- 🔄 **CI/CD Pipeline**: Automated deployment
- 🌍 **Multi-region**: High availability setup
- 🎓 **Advanced features**: Custom modules, integrations

### 💡 Pro Tips:

1. **💰 Always monitor costs** - Set up billing alerts ngay từ đầu
2. **🔄 Backup regularly** - Automate backup process
3. **📚 Keep learning** - AWS và Odoo đều update thường xuyên
4. **🤝 Join communities** - Odoo forum, AWS user groups
5. **🔒 Security first** - Regular updates, strong passwords, monitoring

### 🆘 Remember:

- 📖 **README này** sẽ luôn là tài liệu tham khảo chính
- 🔍 **Health check script** để diagnosis vấn đề
- 🗑️ **Cleanup script** khi không cần nữa để tránh bill shock
- 💬 **GitHub Issues** nếu gặp vấn đề hoặc cần hỗ trợ

---

### 🙏 Cảm ơn bạn đã sử dụng hướng dẫn này!

Nếu project này hữu ích, đừng quên:
- ⭐ **Star repository** trên GitHub
- 🤝 **Share** với đồng nghiệp, bạn bè
- 💬 **Contribute** improvements hoặc bug fixes
- 📝 **Feedback** để cải thiện hướng dẫn

**Happy Odoo-ing trên AWS!** 🏢☁️

---

*📅 Last updated: Tháng 1 năm 2025*
*👤 Author: Claude Code Assistant*
*📧 Support: [GitHub Issues](https://github.com/your-repo/issues)*

⭐ **Star this repo if it helped you!** ⭐