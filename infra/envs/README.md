# Environment Configuration

This folder is a root module that composes the reusable network module in ../../modules.

## Local Development vs CI/CD Setup

### Local Development
For local development, you have two options:

**Option 1: Use Environment Variables (Recommended for CI/CD compatibility)**
Set your AWS credentials using environment variables:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"
```

**Option 2: Override the AWS Profile Locally**
If you prefer using AWS profiles for local development:

1. Copy `terraform.tfvars.example` to `terraform.tfvars.local`
2. Set your profile in the local file:
   ```hcl
   aws_profile = "your-profile-name"
   ```
3. Use the local file when running terraform:
   ```bash
   terraform plan -var-file="terraform.tfvars" -var-file="terraform.tfvars.local"
   terraform apply -var-file="terraform.tfvars" -var-file="terraform.tfvars.local"
   ```

### CI/CD Configuration
The main `terraform.tfvars` file is configured for CI/CD environments:
- `aws_profile = ""` - Uses default AWS provider authentication
- AWS credentials are provided via GitHub Secrets or IAM roles

## Usage
- Copy one of the tfvars under dev/staging/prod and adjust values.
- Optional: set AZs and custom subnet CIDRs. If omitted, they are derived from vpc_cidr.
- Toggle feature flags like enable_nat_gateway, enable_flow_logs, enable_nacls.

Outputs provide VPC and subnet IDs to attach compute resources later.
