# AWS Three-Tier Architecture with Terraform and CI/CD

This project deploys a three-tier network architecture in AWS using Terraform with GitOps-ready CI/CD workflows.

## 🏗️ Architecture Overview

The project creates a robust three-tier network architecture:

- **Public Tier**: Public subnets for load balancers and NAT gateways
- **Private App Tier**: Private subnets for application servers
- **Private DB Tier**: Private subnets for databases

## 🚀 Features

- **Three-tier VPC** with public, private app, and private DB subnets
- **Multi-AZ deployment** for high availability
- **NAT Gateway** for private subnet internet access
- **VPC Flow Logs** (optional)
- **Network ACLs** (optional)
- **GitOps workflow** with GitHub Actions
- **Automated Terraform plan/apply** on pull requests and merges

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

Copy `terraform.tfvars.example` to `terraform.tfvars` in the project root and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Key configuration options:

```hcl
# Basic Configuration
region = "us-west-2"
env_name = "dev"
project_prefix = "three-tier"
aws_profile = ""  # Leave empty for default AWS profile

# Network Configuration
vpc_cidr = "10.0.0.0/16"
az_count = 2

# Network Feature Flags
enable_nat_gateway = true
single_nat_gateway = true  # Set to false for HA (one NAT per AZ)
enable_flow_logs   = false # Enable for network monitoring
enable_nacls       = false # Enable for additional security

# Resource Tags
tags = {
  Environment = "dev"
  Project     = "three-tier-architecture"
  Owner       = "platform-team"
  ManagedBy   = "terraform"
}
```

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

- `vpc_id` - VPC ID
- `public_subnet_ids` - List of public subnet IDs
- `private_app_subnet_ids` - List of private app subnet IDs
- `private_db_subnet_ids` - List of private DB subnet IDs

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