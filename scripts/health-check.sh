#!/bin/bash

# Health Check Script cho Odoo Community 18
# Kiểm tra trạng thái tất cả services và thông tin hệ thống

set -e

echo "=========================================="
echo "🏥 ODOO HEALTH CHECK"
echo "Thời gian: $(date)"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check service status
check_service() {
    local service_name=$1
    local display_name=$2

    if systemctl is-active --quiet $service_name; then
        echo -e "✅ $display_name: ${GREEN}RUNNING${NC}"
        return 0
    else
        echo -e "❌ $display_name: ${RED}STOPPED${NC}"
        return 1
    fi
}

# Function to check port
check_port() {
    local port=$1
    local service_name=$2

    if netstat -tlnp | grep -q ":$port "; then
        echo -e "✅ Port $port ($service_name): ${GREEN}LISTENING${NC}"
        return 0
    else
        echo -e "❌ Port $port ($service_name): ${RED}NOT LISTENING${NC}"
        return 1
    fi
}

# Function to check HTTP endpoint
check_http() {
    local url=$1
    local service_name=$2

    if curl -s -o /dev/null -w "%{http_code}" $url | grep -q "200\|302"; then
        echo -e "✅ HTTP $service_name: ${GREEN}OK${NC}"
        return 0
    else
        echo -e "❌ HTTP $service_name: ${RED}FAILED${NC}"
        return 1
    fi
}

# System Information
echo "💻 SYSTEM INFORMATION"
echo "----------------------------------------"
echo "Hostname: $(hostname)"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Timezone: $(timedatectl show --property=Timezone --value)"
echo ""

# Uptime
echo "⏱️  SYSTEM UPTIME"
echo "----------------------------------------"
uptime
echo ""

# Memory and Disk Usage
echo "💾 RESOURCE USAGE"
echo "----------------------------------------"
echo "Memory Usage:"
free -h
echo ""
echo "Disk Usage:"
df -h /
echo ""

# Network Information
echo "🌐 NETWORK INFORMATION"
echo "----------------------------------------"
echo "Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'N/A')"
echo "Private IP: $(hostname -I | awk '{print $1}')"
echo ""

# Service Status
echo "🔧 SERVICE STATUS"
echo "----------------------------------------"
services_ok=0
total_services=0

# Check PostgreSQL
((total_services++))
if check_service postgresql "PostgreSQL"; then
    ((services_ok++))
fi

# Check Nginx
((total_services++))
if check_service nginx "Nginx"; then
    ((services_ok++))
fi

# Check Odoo
((total_services++))
if check_service odoo "Odoo"; then
    ((services_ok++))
fi

echo ""

# Port Status
echo "🔌 PORT STATUS"
echo "----------------------------------------"
ports_ok=0
total_ports=0

# Check PostgreSQL port
((total_ports++))
if check_port 5432 "PostgreSQL"; then
    ((ports_ok++))
fi

# Check Nginx port
((total_ports++))
if check_port 80 "Nginx"; then
    ((ports_ok++))
fi

# Check Odoo port
((total_ports++))
if check_port 8069 "Odoo"; then
    ((ports_ok++))
fi

echo ""

# HTTP Health Checks
echo "🌐 HTTP HEALTH CHECKS"
echo "----------------------------------------"
http_ok=0
total_http=0

# Check Nginx
((total_http++))
if check_http "http://localhost/" "Nginx"; then
    ((http_ok++))
fi

# Check Odoo
((total_http++))
if check_http "http://localhost:8069/web/database/selector" "Odoo"; then
    ((http_ok++))
fi

echo ""

# Database Connectivity
echo "🗃️  DATABASE CONNECTIVITY"
echo "----------------------------------------"
if sudo -u postgres psql -d odoo18 -c "SELECT 1;" &>/dev/null; then
    echo -e "✅ Database 'odoo18': ${GREEN}ACCESSIBLE${NC}"

    # Count records in res_users table
    user_count=$(sudo -u postgres psql -d odoo18 -t -c "SELECT COUNT(*) FROM res_users WHERE active=true;" 2>/dev/null | tr -d ' ')
    if [[ -n "$user_count" && "$user_count" -gt 0 ]]; then
        echo -e "✅ Active Users: ${GREEN}$user_count${NC}"
    fi

    db_ok=1
else
    echo -e "❌ Database 'odoo18': ${RED}NOT ACCESSIBLE${NC}"
    db_ok=0
fi

echo ""

# Log File Status
echo "📄 LOG FILES"
echo "----------------------------------------"
logs_ok=0
total_logs=0

# Check Odoo log
((total_logs++))
if [[ -f "/var/log/odoo/odoo.log" ]]; then
    log_size=$(du -h /var/log/odoo/odoo.log | cut -f1)
    echo -e "✅ Odoo Log: ${GREEN}EXISTS${NC} (Size: $log_size)"

    # Show last few lines
    echo "   Last 3 lines:"
    tail -n 3 /var/log/odoo/odoo.log | sed 's/^/   /'
    ((logs_ok++))
else
    echo -e "❌ Odoo Log: ${RED}NOT FOUND${NC}"
fi

# Check Nginx logs
((total_logs++))
if [[ -f "/var/log/nginx/odoo.access.log" ]]; then
    log_size=$(du -h /var/log/nginx/odoo.access.log | cut -f1)
    echo -e "✅ Nginx Access Log: ${GREEN}EXISTS${NC} (Size: $log_size)"
    ((logs_ok++))
else
    echo -e "❌ Nginx Access Log: ${RED}NOT FOUND${NC}"
fi

echo ""

# Overall Status
echo "📊 OVERALL STATUS"
echo "----------------------------------------"
total_checks=$((total_services + total_ports + total_http + 1 + total_logs))  # +1 for database
passed_checks=$((services_ok + ports_ok + http_ok + db_ok + logs_ok))

percentage=$((passed_checks * 100 / total_checks))

if [[ $percentage -eq 100 ]]; then
    echo -e "🎉 System Status: ${GREEN}EXCELLENT${NC} ($passed_checks/$total_checks checks passed)"
    health_status="HEALTHY"
elif [[ $percentage -ge 80 ]]; then
    echo -e "✅ System Status: ${GREEN}GOOD${NC} ($passed_checks/$total_checks checks passed)"
    health_status="HEALTHY"
elif [[ $percentage -ge 60 ]]; then
    echo -e "⚠️  System Status: ${YELLOW}WARNING${NC} ($passed_checks/$total_checks checks passed)"
    health_status="WARNING"
else
    echo -e "❌ System Status: ${RED}CRITICAL${NC} ($passed_checks/$total_checks checks passed)"
    health_status="CRITICAL"
fi

echo ""

# Quick Actions
echo "🔧 QUICK ACTIONS"
echo "----------------------------------------"
echo "Restart Odoo:     sudo systemctl restart odoo"
echo "Restart Nginx:    sudo systemctl restart nginx"
echo "View Odoo logs:   sudo tail -f /var/log/odoo/odoo.log"
echo "Check processes:  ps aux | grep -E '(odoo|nginx|postgres)'"
echo ""

# Export status for monitoring
echo "HEALTH_STATUS=$health_status" > /tmp/odoo-health-status.env
echo "CHECKS_PASSED=$passed_checks" >> /tmp/odoo-health-status.env
echo "TOTAL_CHECKS=$total_checks" >> /tmp/odoo-health-status.env
echo "PERCENTAGE=$percentage" >> /tmp/odoo-health-status.env

echo "=========================================="
echo "Health check hoàn thành: $(date)"
echo "Results saved to: /tmp/odoo-health-status.env"
echo "=========================================="

# Exit with appropriate code
if [[ $percentage -ge 80 ]]; then
    exit 0  # Healthy
elif [[ $percentage -ge 60 ]]; then
    exit 1  # Warning
else
    exit 2  # Critical
fi