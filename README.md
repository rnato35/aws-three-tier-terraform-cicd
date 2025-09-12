# AWS Three-Tier Architecture with Terraform and CI/CD

This project deploys a complete, production-ready three-tier web application architecture in AWS using Terraform with GitOps-ready CI/CD workflows.

## 🏗️ Architecture Overview

This project creates a comprehensive three-tier architecture with a working web application:

### **Tier 1: Web/Presentation Layer**
- **Application Load Balancer (ALB)** with SSL termination
- **Auto Scaling Group** with EC2 instances in private subnets
- **HTTPS/SSL** encryption with ACM certificates

### **Tier 2: Application Layer** 
- **EC2 instances** running PHP web application
- **Auto Scaling** with configurable min/max capacity
- **Security Groups** allowing only necessary traffic
- **Sample web application** that connects to the database

### **Tier 3: Database Layer**
- **RDS MySQL** database with Multi-AZ support
- **Database subnet group** in private subnets
- **Automated database initialization** with sample data
- **Encrypted storage** for security

## 🚀 Features

### **Infrastructure**
- **Complete three-tier architecture** with web, app, and database layers
- **High availability** across multiple Availability Zones
- **Auto Scaling** for dynamic capacity management
- **Load balancing** with health checks
- **Secure networking** with proper security group rules
- **Encrypted storage** and secure communications

### **Web Application**
- **One-click deployment** - no manual configuration needed
- **SSL certificate support** for HTTPS encryption
- **Database connectivity** with sample data display
- **Beautiful web interface** showing architecture status
- **Real-time monitoring** of all tiers

### **DevOps & Automation**
- **Professional CI/CD pipeline** with GitHub Actions
- **Multi-environment support** (dev, staging, prod)
- **Automated testing** with terraform plan on PRs
- **Environment-specific deployments**
- **Manual destroy workflows** for cost management
- **Comprehensive deployment summaries**

## 📁 Project Structure

```
aws-three-tier-terraform-cicd/
├── .github/workflows/
│   └── terraform.yml          # CI/CD workflow
├── infra/envs/
│   ├── main.tf                # Main infrastructure configuration
│   ├── variables.tf           # Input variables
│   ├── locals.tf              # Local values
│   └── versions.tf            # Terraform and provider versions
├── modules/network/
│   ├── main.tf                # Network module implementation
│   ├── variables.tf           # Network module variables
│   └── outputs.tf             # Network module outputs
└── scripts/                   # Helper scripts
```

## 🛠️ Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.8.0
- GitHub repository with required secrets and variables

## 🔧 Configuration

### Required GitHub Secrets

```
AWS_ACCESS_KEY_ID      # AWS access key
AWS_SECRET_ACCESS_KEY  # AWS secret key
```

### Required GitHub Variables

```
AWS_REGION            # AWS region (e.g., us-west-2)
```

### Terraform Variables

Copy `terraform.tfvars.example` to `infra/envs/{environment}/terraform.tfvars` and customize:

```bash
# Example for dev environment
cp terraform.tfvars.example infra/envs/dev/terraform.tfvars
```

**Required Configuration:**

```hcl
# Basic Configuration
region = "us-west-2"
env_name = "dev"
project_prefix = "three-tier"
aws_profile = "your-aws-profile"

# Network Configuration  
vpc_cidr = "10.0.0.0/16"
az_count = 2

# Application Configuration (REQUIRED)
certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/your-certificate-id"
domain_name     = "yourdomain.com"  # Used for ALB listener, NOT for DNS creation
subdomain       = "demo"            # Creates subdomain.yourdomain.com

# Database Configuration
db_password = "YourSecurePassword123!"

# Web Tier Scaling
web_min_capacity     = 1
web_max_capacity     = 3
web_desired_capacity = 2
```

### DNS Configuration (External)

⚠️ **Important**: This project does **NOT** create DNS records. You must manually configure your DNS provider to point your domain/subdomain to the ALB DNS name:

1. Deploy the infrastructure with Terraform
2. Get the ALB DNS name from terraform outputs: `terraform output load_balancer_dns_name`  
3. Create a CNAME record in your DNS provider: `demo.yourdomain.com` → `your-alb-dns-name.us-west-2.elb.amazonaws.com`

## 🚀 Deployment

### GitOps Workflow

1. **Fork or clone** this repository
2. **Configure** the required secrets and variables in your GitHub repository
3. **Create a feature branch** and make your changes
4. **Open a pull request** - this will trigger:
   - Terraform format check
   - Terraform validation
   - Terraform plan (with output in PR comments)
5. **Merge to main** - this will trigger:
   - Terraform apply with auto-approval

### Manual Deployment

If you prefer manual deployment:

```bash
cd infra/envs
terraform init
terraform plan
terraform apply
```

## 📊 Outputs

The deployment provides the following outputs:

### **Network Outputs**
- `vpc_id` - VPC ID
- `public_subnet_ids` - List of public subnet IDs
- `private_app_subnet_ids` - List of private app subnet IDs
- `private_db_subnet_ids` - List of private DB subnet IDs

### **Application Outputs**
- `application_url` - HTTPS URL of the application (requires DNS setup)
- `load_balancer_dns_name` - ALB DNS name (use this for DNS provider CNAME)
- `auto_scaling_group_name` - Auto Scaling Group name
- `database_endpoint` - RDS endpoint (sensitive)

## 🗑️ Cleanup

To destroy the infrastructure:

```bash
cd infra/envs
terraform destroy
```

## 📝 Best Practices

- **Environment separation**: Use different `terraform.tfvars` files for different environments
- **State management**: Configure remote state storage (S3 + DynamoDB) for production
- **Security**: Enable VPC Flow Logs and Network ACLs in production environments
- **Cost optimization**: Consider using a single NAT Gateway for non-production environments

## 🔐 Security Considerations

- Private subnets have no direct internet access
- NAT Gateway provides controlled internet access for private resources
- Network ACLs can be enabled for additional network-level security
- VPC Flow Logs can be enabled for network monitoring

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.