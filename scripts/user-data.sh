#!/bin/bash

# Script cài đặt Odoo Community 18 trên Ubuntu 22.04
# Tự động hóa hoàn toàn quá trình cài đặt

# Log tất cả output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Bắt đầu cài đặt Odoo Community 18"
echo "Thời gian: $(date)"
echo "=========================================="

# Update hệ thống
echo "1. Cập nhật hệ thống..."
apt-get update -y
apt-get upgrade -y

# Set timezone
echo "2. Cấu hình timezone..."
timedatectl set-timezone Asia/Ho_Chi_Minh

# Cài đặt các packages cần thiết
echo "3. Cài đặt packages cần thiết..."

# Python và development tools
apt-get install -y python3 python3-pip python3-dev python3-venv python3-wheel
apt-get install -y build-essential wget git curl

# Libraries cho Odoo
apt-get install -y libxml2-dev libxslt1-dev libevent-dev
apt-get install -y libsasl2-dev libldap2-dev libpq-dev
apt-get install -y libpng-dev libjpeg-dev libfreetype6-dev
apt-get install -y zlib1g-dev

# Web server
apt-get install -y nginx

# Database
apt-get install -y postgresql postgresql-contrib

# PDF generation
apt-get install -y wkhtmltopdf

# Node.js (cho một số Odoo modules)
apt-get install -y nodejs npm

echo "4. Cấu hình PostgreSQL..."

# Start PostgreSQL
systemctl enable postgresql
systemctl start postgresql

# Wait for PostgreSQL to be ready
sleep 5

# Tạo database user và database
echo "Tạo PostgreSQL user và database..."
sudo -u postgres createuser -d -R -S odoo
sudo -u postgres psql -c "ALTER USER odoo WITH PASSWORD 'odoo123';"
sudo -u postgres createdb -O odoo odoo18

echo "5. Tạo system user cho Odoo..."
useradd -m -d /opt/odoo -U -r -s /bin/bash odoo

echo "6. Download Odoo Community 18..."
cd /opt

# Clone Odoo repository
git clone --depth 1 --branch 18.0 https://www.github.com/odoo/odoo.git

# Change ownership
chown -R odoo:odoo /opt/odoo

echo "7. Cài đặt Python dependencies..."
cd /opt/odoo

# Upgrade pip
python3 -m pip install --upgrade pip

# Install requirements
pip3 install -r requirements.txt

# Install some additional useful packages
pip3 install psycopg2-binary

echo "8. Tạo thư mục logs và configs..."

# Tạo thư mục logs
mkdir -p /var/log/odoo
chown odoo:odoo /var/log/odoo

# Tạo thư mục cho PID files
mkdir -p /var/run/odoo
chown odoo:odoo /var/run/odoo

echo "9. Tạo Odoo configuration file..."

cat > /etc/odoo.conf << 'EOF'
[options]
; Cấu hình cho Odoo Community 18
addons_path = /opt/odoo/addons
admin_passwd = admin123
csv_internal_sep = ,
db_host = localhost
db_port = 5432
db_user = odoo
db_password = odoo123
db_name = odoo18
db_template = template0
dbfilter = ^odoo18$
demo = {}
email_from = False
http_interface = 0.0.0.0
http_port = 8069
import_partial =
list_db = False
log_db = False
log_db_level = warning
log_handler = :INFO
log_level = info
logfile = /var/log/odoo/odoo.log
longpolling_port = 8072
max_cron_threads = 2
osv_memory_age_limit = False
osv_memory_count_limit = False
pg_path = /usr/bin
pidfile = /var/run/odoo/odoo.pid
proxy_mode = True
reportgz = False
server_wide_modules = base,web
smtp_password = False
smtp_port = 25
smtp_server = localhost
smtp_ssl = False
smtp_user = False
syslog = False
test_enable = False
test_file =
test_tags = None
translate_modules = ['all']
unaccent = False
upgrade_path =
without_demo = False
workers = 0
EOF

chown odoo:odoo /etc/odoo.conf

echo "10. Tạo systemd service cho Odoo..."

cat > /etc/systemd/system/odoo.service << 'EOF'
[Unit]
Description=Odoo Community 18
Documentation=http://www.odoo.com
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo
PermissionsStartOnly=true
User=odoo
Group=odoo
ExecStart=/usr/bin/python3 /opt/odoo/odoo-bin -c /etc/odoo.conf
StandardOutput=journal+console
KillMode=mixed
KillSignal=SIGINT
TimeoutStopSec=600
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "11. Cấu hình Nginx..."

cat > /etc/nginx/sites-available/odoo << 'EOF'
# Odoo Community 18 Nginx Configuration
upstream odoo {
    server 127.0.0.1:8069;
}

upstream odoolong {
    server 127.0.0.1:8072;
}

server {
    listen 80;
    server_name _;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logs
    access_log /var/log/nginx/odoo.access.log;
    error_log /var/log/nginx/odoo.error.log;

    # Increase proxy timeouts
    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;

    # Proxy headers
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;

    # Main Odoo location
    location / {
        proxy_redirect off;
        proxy_pass http://odoo;
    }

    # Longpolling for real-time features
    location /longpolling {
        proxy_pass http://odoolong;
    }

    # Static files caching
    location ~* /web/static/ {
        proxy_cache_valid 200 90m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://odoo;
    }

    # Favicon
    location /favicon.ico {
        access_log off;
        log_not_found off;
    }

    # Robots.txt
    location /robots.txt {
        access_log off;
        log_not_found off;
    }

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;
}
EOF

# Enable site và disable default
ln -sf /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
nginx -t

echo "12. Enable services..."

# Reload systemd
systemctl daemon-reload

# Enable services
systemctl enable odoo
systemctl enable nginx

echo "13. Restart services..."

# Restart PostgreSQL
systemctl restart postgresql

# Restart Nginx
systemctl restart nginx

echo "14. Khởi tạo Odoo database..."

# Wait for PostgreSQL to be fully ready
sleep 10

# Initialize Odoo database
echo "Khởi tạo database với base modules..."
sudo -u odoo /usr/bin/python3 /opt/odoo/odoo-bin -c /etc/odoo.conf -d odoo18 -i base --stop-after-init

echo "15. Start Odoo service..."

# Start Odoo
systemctl start odoo

# Wait for Odoo to start
sleep 15

# Check if Odoo is running
if systemctl is-active --quiet odoo; then
    echo "✅ Odoo service đã chạy thành công!"
else
    echo "❌ Lỗi: Odoo service không chạy được"
    systemctl status odoo
fi

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo "=========================================="
echo "🎉 HOÀN THÀNH CÀI ĐẶT ODOO COMMUNITY 18!"
echo "=========================================="
echo "📍 URL truy cập: http://$PUBLIC_IP:8069"
echo "📍 URL qua Nginx: http://$PUBLIC_IP"
echo "🔑 Database: odoo18"
echo "👤 Admin User: admin"
echo "🔐 Admin Password: admin123"
echo "🐘 Database User: odoo"
echo "🔐 Database Password: odoo123"
echo "=========================================="

# Show service status
echo "📊 Trạng thái services:"
echo "PostgreSQL: $(systemctl is-active postgresql)"
echo "Nginx: $(systemctl is-active nginx)"
echo "Odoo: $(systemctl is-active odoo)"
echo "=========================================="

echo "🔧 Để kiểm tra logs:"
echo "sudo tail -f /var/log/odoo/odoo.log"
echo "sudo tail -f /var/log/nginx/odoo.access.log"
echo "sudo journalctl -u odoo -f"
echo "=========================================="

echo "Script hoàn thành lúc: $(date)"