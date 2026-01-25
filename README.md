# Odoo Community 18 AWS Deployment Infrastructure

![Odoo AWS Infrastructure](./assets/odoo-aws-banner.svg)

A production-ready infrastructure automation solution for deploying Odoo Community Edition 18 on Amazon Web Services (AWS) EC2 using CloudFormation. This project provides a complete Infrastructure as Code (IaC) approach with automated installation scripts, monitoring tools, and cost optimization strategies.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Options](#deployment-options)
- [Configuration](#configuration)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Cost Optimization](#cost-optimization)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview

This project automates the deployment of Odoo Community 18 on AWS infrastructure with the following objectives:

- **Cost-effective deployment**: Optimized for AWS Free Tier eligibility
- **Production-ready**: Includes monitoring, logging, and security best practices
- **Fully automated**: One-command deployment using CloudFormation
- **Scalable architecture**: Easy to upgrade instance types and add resources
- **Comprehensive documentation**: Detailed setup and maintenance guides

### Target Architecture

The deployment creates a single-instance architecture suitable for small to medium businesses:

```
Internet Gateway
       |
   VPC (Default)
       |
Security Group (Ports 22, 80, 8069)
       |
EC2 Instance (Ubuntu 22.04 LTS)
├── Nginx (Reverse Proxy)
├── Odoo Community 18
└── PostgreSQL 14
```

## Architecture

### Infrastructure Components

| Component | Specification | Purpose |
|-----------|---------------|---------|
| **EC2 Instance** | t2.micro (1 vCPU, 1GB RAM) | Application server |
| **Operating System** | Ubuntu 22.04 LTS | Stable Linux distribution |
| **Database** | PostgreSQL 14 | Odoo data storage |
| **Web Server** | Nginx | Reverse proxy and static files |
| **Storage** | 8GB GP2 EBS | Root volume |
| **Network** | Default VPC | AWS networking |

### Software Stack

- **Odoo Community 18**: Latest stable release from official repository
- **PostgreSQL 14**: Database server with optimized configuration
- **Nginx**: HTTP reverse proxy with caching
- **Python 3.10**: Runtime environment for Odoo
- **Systemd**: Service management for Odoo processes

## Features

### Automation Features
- Complete CloudFormation template for infrastructure provisioning
- Automated software installation via EC2 User Data scripts
- Service configuration and startup automation
- Health check and monitoring scripts

### Deployment Features
- Multiple deployment methods (CLI, Console, Script)
- Parameterized CloudFormation with customizable options
- Support for different instance types and regions
- SSH key pair integration for secure access

### Monitoring Features
- Comprehensive health check script
- System resource monitoring
- Application log management
- Service status verification

### Management Features
- Automated backup procedures
- Cleanup and resource removal scripts
- Cost monitoring and optimization guides
- Security hardening recommendations

## Prerequisites

### AWS Account Setup

1. **AWS Account**: Active AWS account with administrative privileges
2. **Payment Method**: Valid credit card for AWS services
3. **Service Limits**: Ensure EC2 instance limits allow t2.micro instances
4. **Region Access**: Deployment tested in ap-southeast-1 (Singapore)

### Required Tools

| Tool | Purpose | Installation |
|------|---------|-------------|
| **AWS CLI v2** | AWS service management | [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| **Git** | Repository management | [Download Git](https://git-scm.com/) |
| **SSH Client** | Server access | Built-in (Linux/Mac) or PuTTY (Windows) |

### AWS Credentials Configuration

Create IAM user with the following minimum permissions:
- EC2 full access
- CloudFormation full access
- IAM read access for credential verification

## Quick Start

### Step 1: Clone Repository

```bash
git clone https://github.com/your-username/odoo-community-aws-deployment.git
cd odoo-community-aws-deployment
```

### Step 2: Configure AWS Credentials

```bash
aws configure
# Provide: Access Key ID, Secret Access Key, Region (ap-southeast-1), Output format (json)
```

### Step 3: Create EC2 Key Pair (Optional)

```bash
# Create key pair for SSH access
aws ec2 create-key-pair --key-name odoo-keypair --query 'KeyMaterial' --output text > odoo-keypair.pem
chmod 600 odoo-keypair.pem
```

### Step 4: Validate Template

```bash
# Test CloudFormation template
./scripts/test-template.sh
```

### Step 5: Deploy Infrastructure

```bash
# Deploy with default settings
./deploy.sh

# Deploy with SSH key for server access
./deploy.sh -k odoo-keypair
```

### Step 6: Access Odoo

After deployment completion (5-10 minutes), access Odoo using the provided URL:

```
URL: http://[PUBLIC-IP]:8069
Database: odoo18
Username: admin
Password: admin123
```

## Deployment Options

### Command Line Deployment

The deployment script supports various parameters for customization:

```bash
# Basic deployment
./deploy.sh

# Custom stack name
./deploy.sh --name production-odoo

# Different instance type
./deploy.sh --type t2.small

# Specific region
./deploy.sh --region us-west-2

# With SSH access
./deploy.sh --key my-keypair

# Full customization
./deploy.sh --name prod-odoo --type t2.small --key prod-key --region us-west-2
```

### Parameter Reference

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| `-n, --name` | CloudFormation stack name | odoo-community-18 | `--name prod-odoo` |
| `-t, --type` | EC2 instance type | t2.micro | `--type t2.small` |
| `-k, --key` | EC2 key pair name | None | `--key my-keypair` |
| `-r, --region` | AWS region | ap-southeast-1 | `--region us-east-1` |

### AWS Console Deployment

1. Navigate to CloudFormation in AWS Console
2. Create new stack with existing resources
3. Upload `cloudformation/odoo-simple.yaml`
4. Configure parameters
5. Create stack and monitor deployment

### Manual CLI Deployment

```bash
# Validate template
aws cloudformation validate-template --template-body file://cloudformation/odoo-simple.yaml

# Deploy stack
aws cloudformation create-stack \
  --stack-name odoo-community-18 \
  --template-body file://cloudformation/odoo-simple.yaml \
  --parameters ParameterKey=InstanceType,ParameterValue=t2.micro

# Monitor deployment
aws cloudformation describe-stack-events --stack-name odoo-community-18
```

## Configuration

### Odoo Configuration

The Odoo configuration file (`/etc/odoo.conf`) includes optimized settings:

```ini
[options]
addons_path = /opt/odoo/addons
admin_passwd = admin123
db_host = localhost
db_port = 5432
db_user = odoo
db_password = odoo123
db_name = odoo18
http_interface = 0.0.0.0
http_port = 8069
logfile = /var/log/odoo/odoo.log
proxy_mode = True
```

### Database Configuration

PostgreSQL is configured with the following parameters:
- **Database Name**: odoo18
- **Database User**: odoo
- **Connection**: localhost:5432
- **Encoding**: UTF-8

### Nginx Configuration

Nginx serves as a reverse proxy with the following features:
- HTTP to Odoo proxy on port 8069
- Static file caching
- Gzip compression
- Security headers

## Monitoring and Maintenance

### Health Check Script

The included health check script monitors system components:

```bash
# Run comprehensive health check
sudo ./scripts/health-check.sh
```

**Monitored Components:**
- Odoo service status
- PostgreSQL availability
- Nginx functionality
- Port connectivity
- Database accessibility
- System resources

### Log Management

**Log Locations:**
- Odoo Application: `/var/log/odoo/odoo.log`
- Nginx Access: `/var/log/nginx/odoo.access.log`
- Nginx Error: `/var/log/nginx/odoo.error.log`
- System: `journalctl -u odoo`

**Log Monitoring Commands:**
```bash
# Real-time Odoo logs
sudo tail -f /var/log/odoo/odoo.log

# Service status
sudo systemctl status odoo

# System resource usage
htop
df -h
```

### Service Management

**Odoo Service:**
```bash
sudo systemctl start|stop|restart|status odoo
```

**PostgreSQL Service:**
```bash
sudo systemctl start|stop|restart|status postgresql
```

**Nginx Service:**
```bash
sudo systemctl start|stop|restart|status nginx
```

### Backup Procedures

**Database Backup:**
```bash
# Create backup
sudo -u postgres pg_dump odoo18 > backup_$(date +%Y%m%d).sql

# Restore backup
sudo -u postgres psql odoo18 < backup_file.sql
```

**File System Backup:**
```bash
# Backup Odoo files
sudo tar -czf odoo_backup_$(date +%Y%m%d).tar.gz /opt/odoo/filestore
```

## Cost Optimization

### Cost Analysis

**Monthly Costs (ap-southeast-1):**

| Resource | Free Tier | Post Free Tier |
|----------|-----------|----------------|
| EC2 t2.micro (750h) | $0.00 | $8.47 |
| EBS Storage (8GB) | $0.00 | $0.80 |
| Data Transfer (15GB) | $0.00 | $0.90 |
| **Total** | **$0.00** | **$10.17** |

### Optimization Strategies

**1. Reserved Instances**
```bash
# Purchase 1-year Reserved Instance (40% savings)
aws ec2 purchase-reserved-instances-offering \
  --reserved-instances-offering-id [OFFERING-ID] \
  --instance-count 1
```

**2. Instance Scheduling**
- Implement Lambda functions for automatic start/stop
- Use CloudWatch Events for scheduling
- Potential 60% cost reduction for non-24/7 operations

**3. Resource Monitoring**
```bash
# Set up billing alerts
aws budgets create-budget \
  --account-id [ACCOUNT-ID] \
  --budget file://budget-config.json
```

**4. Storage Optimization**
- Regular log rotation
- Database maintenance (VACUUM, REINDEX)
- Unnecessary file cleanup

### Instance Type Comparison

| Instance Type | vCPU | Memory | Monthly Cost | Recommended Use |
|---------------|------|--------|--------------|-----------------|
| t2.micro | 1 | 1GB | $8.47 | Development, <5 users |
| t2.small | 1 | 2GB | $16.94 | Small business, <10 users |
| t2.medium | 2 | 4GB | $33.87 | Growing business, <25 users |
| t3.small | 2 | 2GB | $18.98 | Better performance than t2 |

## Security Considerations

### Network Security

**Security Group Configuration:**
- SSH (Port 22): Restricted to specific IP ranges
- HTTP (Port 80): Open to internet
- Odoo (Port 8069): Open to internet
- PostgreSQL (Port 5432): Localhost only

**Firewall Configuration:**
```bash
# Enable UFW firewall
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 8069/tcp
```

### Application Security

**1. Change Default Passwords**
```bash
# Change Odoo admin password via web interface
# Settings > Users & Companies > Users > Administrator
```

**2. Database Security**
```bash
# Change PostgreSQL passwords
sudo -u postgres psql -c "ALTER USER odoo WITH PASSWORD 'new-secure-password';"
```

**3. SSH Hardening**
```bash
# Disable password authentication
sudo nano /etc/ssh/sshd_config
# PasswordAuthentication no
# PermitRootLogin no
sudo systemctl restart ssh
```

**4. SSL Implementation**
For production deployments, implement SSL/TLS:
- Use Let's Encrypt for free certificates
- Configure Nginx for HTTPS
- Redirect HTTP to HTTPS

### Security Best Practices

- Regular system updates
- Strong password policies
- Multi-factor authentication for admin accounts
- Regular security audits
- Backup encryption
- Access logging and monitoring

## Troubleshooting

### Common Issues and Solutions

**Issue: Cannot access Odoo web interface**

*Symptoms:* Browser timeout, connection refused

*Solutions:*
1. Verify Security Group allows port 8069
2. Check Odoo service status: `sudo systemctl status odoo`
3. Verify port binding: `sudo netstat -tlnp | grep 8069`
4. Check firewall rules: `sudo ufw status`

**Issue: Odoo service fails to start**

*Symptoms:* Service in failed state, error logs

*Solutions:*
1. Check logs: `sudo journalctl -u odoo -n 50`
2. Verify configuration: `sudo odoo --config=/etc/odoo.conf --test-enable`
3. Check permissions: `sudo chown -R odoo:odoo /opt/odoo`
4. Database connectivity: `sudo -u postgres psql -d odoo18 -c "SELECT 1;"`

**Issue: Database connection errors**

*Symptoms:* Database connection refused, authentication failed

*Solutions:*
1. PostgreSQL status: `sudo systemctl status postgresql`
2. Reset password: `sudo -u postgres psql -c "ALTER USER odoo WITH PASSWORD 'odoo123';"`
3. Recreate database: `sudo -u postgres createdb -O odoo odoo18`

**Issue: Memory exhaustion (t2.micro)**

*Symptoms:* Services crashing, slow response times

*Solutions:*
1. Add swap file:
   ```bash
   sudo fallocate -l 1G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```
2. Upgrade to t2.small instance type
3. Optimize Odoo configuration for low memory

**Issue: High CPU usage**

*Solutions:*
1. Monitor processes: `htop`
2. Optimize database queries
3. Enable Odoo worker processes (for larger instances)
4. Implement caching strategies

### Diagnostic Commands

**System Health:**
```bash
# System resources
free -h
df -h
top

# Network connectivity
curl -I http://localhost:8069
netstat -tlnp | grep -E "(80|8069|5432)"

# Service status
systemctl status odoo nginx postgresql
```

**Application Health:**
```bash
# Odoo logs
sudo tail -f /var/log/odoo/odoo.log

# Database connectivity
sudo -u postgres psql -d odoo18 -c "\l"

# Nginx configuration test
sudo nginx -t
```

### Performance Tuning

**For t2.micro instances:**
```ini
# /etc/odoo.conf optimizations
workers = 0  # Single process mode
max_cron_threads = 1
limit_memory_hard = 671088640  # 640MB
limit_memory_soft = 629145600  # 600MB
```

**PostgreSQL optimizations:**
```sql
-- /etc/postgresql/14/main/postgresql.conf
shared_buffers = 128MB
effective_cache_size = 512MB
work_mem = 4MB
```

## Resource Cleanup

### Automated Cleanup

Use the provided cleanup script to remove all AWS resources:

```bash
# Remove specific stack
./scripts/cleanup.sh --name odoo-community-18

# Force removal without confirmation
./scripts/cleanup.sh --name odoo-community-18 --force
```

### Manual Cleanup

**CloudFormation:**
```bash
# Delete stack
aws cloudformation delete-stack --stack-name odoo-community-18

# Monitor deletion
aws cloudformation describe-stack-events --stack-name odoo-community-18
```

**Verify Resource Removal:**
```bash
# Check remaining instances
aws ec2 describe-instances --filters "Name=tag:aws:cloudformation:stack-name,Values=odoo-community-18"

# Check security groups
aws ec2 describe-security-groups --filters "Name=tag:aws:cloudformation:stack-name,Values=odoo-community-18"
```

## Contributing

We welcome contributions to improve this deployment solution. Please follow these guidelines:

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/improvement`
3. Make changes and test thoroughly
4. Submit a pull request with detailed description

### Code Standards

- CloudFormation templates must pass validation
- Shell scripts must be POSIX-compliant
- Include appropriate error handling
- Update documentation for new features

### Testing

Before submitting changes:
1. Validate CloudFormation templates
2. Test deployment in clean AWS environment
3. Verify cleanup procedures
4. Test on different instance types

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) file for details.

## Support

### Documentation

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [Odoo Community Documentation](https://www.odoo.com/documentation/18.0/)
- [EC2 User Guide](https://docs.aws.amazon.com/ec2/)

### Community Support

- GitHub Issues for bug reports and feature requests
- AWS Community Forums for infrastructure questions
- Odoo Community Forum for application support

### Professional Services

For enterprise deployments, custom integrations, or professional support:
- AWS Professional Services
- Odoo Implementation Partners
- Third-party DevOps consultants

---

**Disclaimer**: This project is not officially affiliated with Odoo SA or Amazon Web Services. Use at your own risk and ensure compliance with your organization's security policies.