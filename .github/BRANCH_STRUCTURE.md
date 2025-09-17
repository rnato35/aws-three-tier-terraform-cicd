# Repository Structure

This repository supports manual deployment with environment-specific configurations for infrastructure and applications.

## Environment Configuration

### Infrastructure Environments
- `infra/envs/dev/` - Development infrastructure configuration
- `infra/envs/staging/` - Staging infrastructure configuration
- `infra/envs/prod/` - Production infrastructure configuration

### Application Environments
- `modules/applications/values/dev/` - Development application values
- `modules/applications/values/staging/` - Staging application values
- `modules/applications/values/prod/` - Production application values

## Initial Setup Commands

After cloning the repository, configure your environment:

```bash
# Clone the repository
git clone <your-repo>
cd one-click-aws-three-tier-foundation

# Configure AWS CLI (if not already done)
aws configure

# Install required tools
# - Terraform
# - kubectl
# - Helm
# - AWS CLI
```

## Manual Deployment Process

### Infrastructure Changes
- **Configuration**: Edit files in `infra/envs/**` or `modules/**`
- **Deployment**: Use terraform commands with appropriate environment configs
- **Environments**: dev, staging, prod

### Application Changes
- **Configuration**: Edit files in `modules/applications/**`
- **Deployment**: Use terraform/helm commands for application deployment
- **Environments**: dev, staging, prod

## Deployment Workflow

### Infrastructure Deployment
1. Edit configuration files in `infra/envs/{env}/terraform.tfvars`
2. Run `terraform plan` to review changes
3. Run `terraform apply` to deploy changes
4. Repeat for other environments as needed

### Application Deployment
1. Edit application configurations in `modules/applications/`
2. Run `terraform plan` to review changes
3. Run `terraform apply` to deploy applications
4. Repeat for other environments as needed

## Best Practices

- **Environment Isolation**: Use terraform workspaces to separate environments
- **State Management**: Store terraform state in S3 with DynamoDB locking
- **Security**: Use least-privilege IAM roles and policies
- **Testing**: Always run `terraform plan` before applying changes
- **Documentation**: Keep environment-specific notes and configurations updated