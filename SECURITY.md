# Security Implementation

This project implements several security best practices for managing sensitive data, particularly database passwords.

## Database Password Security

### GitHub Actions CI/CD
The database password is securely managed using:

1. **GitHub Secrets**: Store the `DB_PASSWORD` secret in your GitHub repository
   - Go to Settings > Secrets and variables > Actions
   - Add a new repository secret named `DB_PASSWORD`
   - Set a strong password value

2. **Environment Variables**: The GitHub Actions workflow uses `TF_VAR_db_password` environment variable
   - Terraform automatically picks up variables prefixed with `TF_VAR_`
   - The password is never stored in plain text in the repository

### AWS Secrets Manager
For runtime security, the application uses AWS Secrets Manager:

1. **Secrets Storage**: Database password is stored in AWS Secrets Manager
2. **IAM Permissions**: EC2 instances have minimal IAM permissions to retrieve only their specific secret
3. **Runtime Retrieval**: Application code retrieves passwords dynamically from Secrets Manager

### Local Development

For local development, you have two secure options:

#### Option 1: Environment Variable (Recommended)
```bash
export TF_VAR_db_password="YourSecurePassword123!"
terraform plan
terraform apply
```

#### Option 2: Local tfvars file
```bash
# Create terraform.tfvars.local (this file is gitignored)
echo 'db_password = "YourSecurePassword123!"' > terraform.tfvars.local

# Use both files
terraform plan -var-file="terraform.tfvars" -var-file="terraform.tfvars.local"
```

## Security Benefits

1. **No Secrets in Code**: Database passwords are never committed to version control
2. **Encrypted at Rest**: AWS Secrets Manager encrypts secrets using AWS KMS
3. **Encrypted in Transit**: All communication with Secrets Manager uses TLS
4. **Least Privilege**: IAM roles grant minimal permissions needed
5. **Audit Trail**: AWS CloudTrail logs all Secrets Manager access
6. **Rotation Ready**: AWS Secrets Manager supports automatic password rotation

## GitHub Secrets Setup

To set up the required secrets in your GitHub repository:

1. Navigate to your GitHub repository
2. Go to **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Add the following secrets:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `DB_PASSWORD` | Database master password | `SecureP@ssw0rd123!` |
| `AWS_ROLE_ARN` | AWS IAM role ARN for OIDC | `arn:aws:iam::123456789012:role/GitHubActionsRole` |

## Environment-Specific Secrets

For multi-environment setups, you can use GitHub Environment secrets:

1. Create environments: `dev`, `staging`, `prod`
2. Set environment-specific `DB_PASSWORD` secrets
3. Each environment will use its own password automatically

## Best Practices Implemented

- ✅ Secrets never stored in version control
- ✅ Encryption at rest and in transit
- ✅ Minimal IAM permissions (principle of least privilege)
- ✅ Environment variable injection in CI/CD
- ✅ AWS Secrets Manager for runtime security
- ✅ Separate secrets per environment
- ✅ Clear documentation for developers