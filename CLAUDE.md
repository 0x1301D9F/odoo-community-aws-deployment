# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository provides a production-ready Infrastructure as Code (IaC) solution for deploying Odoo Community Edition 18 on AWS EC2 using CloudFormation. The architecture is a single-instance deployment optimized for cost-effectiveness and AWS Free Tier eligibility.

## Core Architecture

The deployment creates:
- EC2 instance (t2.micro by default) running Ubuntu 22.04 LTS
- Nginx as reverse proxy (port 80 → 8069)
- Odoo Community 18 application server
- PostgreSQL 14 database (co-located on same instance)
- Security Group allowing SSH (22), HTTP (80), and Odoo (8069)

## Key Components

### Infrastructure Provisioning
- **CloudFormation Template**: `cloudformation/odoo-simple.yaml` - Complete infrastructure definition
- **User Data Script**: `scripts/user-data.sh` - Embedded in CloudFormation for automatic software installation

### Deployment & Management Scripts
- **Main Deploy**: `deploy.sh` - Primary deployment orchestrator with parameter validation
- **Template Validation**: `scripts/test-template.sh` - Pre-deployment CloudFormation validation
- **Health Monitoring**: `scripts/health-check.sh` - Post-deployment system verification
- **Resource Cleanup**: `scripts/cleanup.sh` - Safe stack and resource removal

### Configuration Templates
- **Odoo Config**: `configs/odoo.conf` - Production-optimized Odoo settings
- **Nginx Config**: `configs/nginx-simple.conf` - Reverse proxy with caching
- **Systemd Service**: `configs/odoo.service` - Service management configuration

## Common Commands

### Deployment Workflow
```bash
# Validate CloudFormation template before deployment
./scripts/test-template.sh

# Deploy with default settings (t2.micro, ap-southeast-1)
./deploy.sh

# Deploy with SSH access and custom instance type
./deploy.sh -k your-keypair -t t2.small -n production-odoo

# Deploy to different region
./deploy.sh -r us-east-1
```

### Validation & Testing
```bash
# Validate AWS credentials and template
aws sts get-caller-identity
aws cloudformation validate-template --template-body file://cloudformation/odoo-simple.yaml

# Monitor deployment progress
aws cloudformation describe-stack-events --stack-name odoo-community-18

# Health check deployed system (run on EC2 instance)
sudo ./scripts/health-check.sh
```

### Resource Management
```bash
# List existing stacks
./scripts/cleanup.sh  # Lists stacks when no name provided

# Remove deployment
./scripts/cleanup.sh -n odoo-community-18

# Force removal without confirmation
./scripts/cleanup.sh -n odoo-community-18 -f
```

## Script Parameter Patterns

All scripts follow consistent parameter conventions:
- `-n, --name`: CloudFormation stack name
- `-r, --region`: AWS region (default: ap-southeast-1)
- `-t, --type`: EC2 instance type (default: t2.micro)
- `-k, --key`: EC2 Key Pair name for SSH access
- `-f, --force`: Skip interactive confirmations
- `-h, --help`: Display usage information

## Key Configuration Values

### Default Deployment Settings
- **Stack Name**: `odoo-community-18`
- **Region**: `ap-southeast-1` (Singapore - cost-optimized)
- **Instance Type**: `t2.micro` (Free Tier eligible)
- **Database**: `odoo18` with user `odoo`/password `odoo123`
- **Admin Access**: `admin`/`admin123`

### Port Mappings
- **SSH**: 22 (Security Group)
- **HTTP**: 80 (Nginx → Odoo proxy)
- **Odoo Direct**: 8069 (application port)
- **Odoo Longpolling**: 8072 (real-time features)
- **PostgreSQL**: 5432 (localhost only)

## Infrastructure Dependencies

The deployment has a strict dependency chain:
1. AWS credentials must be configured (`aws configure`)
2. CloudFormation template validation
3. EC2 instance provisioning
4. User data script execution (Ubuntu updates, software installation)
5. Service configuration and startup (PostgreSQL → Odoo → Nginx)

The user data script handles the complete software stack installation automatically, including system updates, database setup, Odoo installation from GitHub, and service configuration.

## Cost Optimization Context

The architecture is specifically designed for cost minimization:
- Single-instance deployment (no load balancers, RDS, or NAT gateways)
- t2.micro instance (AWS Free Tier eligible)
- Co-located database (no separate RDS instance)
- GP2 storage (8GB minimum)
- Default VPC usage (no custom networking costs)

Monthly cost estimate: $0 (Free Tier) to ~$10.17 (post Free Tier) in ap-southeast-1.

## Security Considerations

Default configuration prioritizes functionality over security for demo purposes:
- Security Groups open to 0.0.0.0/0 for HTTP and Odoo ports
- Default passwords used (should be changed post-deployment)
- SSH key pair is optional but recommended for production

For production deployments, implement additional hardening as documented in the README security section.

## Error Handling Patterns

All scripts implement consistent error handling:
- `set -e` for immediate exit on errors
- AWS CLI availability checks
- Credential validation before AWS operations
- Template validation before deployment
- Interactive confirmations for destructive operations
- Detailed error messages with corrective actions

When troubleshooting deployments, check:
1. AWS credentials and permissions
2. CloudFormation stack events in AWS Console
3. EC2 instance user data logs (`/var/log/user-data.log`)
4. Service status on the instance (`systemctl status odoo nginx postgresql`)