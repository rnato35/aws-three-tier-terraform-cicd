# Manual Workflows

This project includes manual GitHub Actions workflows that can be triggered on-demand for infrastructure management.

## Manual Terraform Operations

### How to Access
1. Go to your GitHub repository
2. Click on the **Actions** tab
3. Select **terraform** workflow from the left sidebar
4. Click **Run workflow** button (appears only on the default branch)

### Available Actions

#### 🔍 Plan
- **Purpose**: Preview changes without applying them
- **Use case**: Check what Terraform will do before making changes
- **Safety**: Read-only operation, no infrastructure changes

#### ✅ Apply  
- **Purpose**: Apply infrastructure changes
- **Use case**: Deploy changes to the selected environment
- **Safety**: Modifies infrastructure, use with caution

#### 🚨 Destroy
- **Purpose**: Destroy all infrastructure in the selected environment
- **Use case**: Clean up environments, cost savings
- **Safety**: **DESTRUCTIVE** - permanently deletes all resources

### Environment Selection
Choose from available environments:
- **dev** - Development environment
- **staging** - Staging environment  
- **prod** - Production environment

### Safety Measures for Destroy

#### 1. Confirmation Required
For destroy operations, you **must** type `DESTROY` in the confirmation field:
- This prevents accidental destruction
- The workflow will fail if confirmation is not provided
- Case-sensitive: must be exactly `DESTROY`

#### 2. Manual Approval Gates
- **Production**: Requires manual approval before destroying
- **Staging**: Requires manual approval before destroying  
- **Dev**: No approval required (faster iteration)

#### 3. Approval Process
When manual approval is required:
1. Workflow creates a GitHub Issue
2. Tagged approvers receive notifications
3. Approver must comment `/approve` on the issue
4. Workflow continues after approval
5. Issue is automatically closed

### Example Usage Scenarios

#### Scenario 1: Check Dev Changes
```
Action: plan
Environment: dev
Confirm Destroy: [leave empty]
```

#### Scenario 2: Deploy to Staging
```
Action: apply
Environment: staging  
Confirm Destroy: [leave empty]
```

#### Scenario 3: Destroy Dev Environment
```
Action: destroy
Environment: dev
Confirm Destroy: DESTROY
```

#### Scenario 4: Destroy Production (High Safety)
```
Action: destroy
Environment: prod
Confirm Destroy: DESTROY
```
→ Creates approval issue
→ Wait for manual approval
→ Destroys after approval

### Monitoring Workflow Progress

1. **Real-time Logs**: View live logs in the Actions tab
2. **Notifications**: Enable GitHub notifications for workflow status
3. **Issues**: Approval requests create temporary GitHub issues
4. **Status Checks**: Workflow status appears on commits

### Best Practices

#### Before Destroying Infrastructure
1. **Backup Data**: Ensure critical data is backed up
2. **Notify Team**: Inform team members before destroying shared environments
3. **Check Dependencies**: Verify no other systems depend on the infrastructure
4. **Cost Consideration**: Understand cost implications of recreation

#### Emergency Procedures
If you need to quickly destroy infrastructure:
1. Use the manual workflow for fastest execution
2. For production, have approver ready to approve quickly
3. Consider partial destroy if only specific resources need removal

#### Troubleshooting
- **Workflow Fails**: Check the logs in GitHub Actions
- **Permission Denied**: Verify GitHub Secrets are configured
- **Terraform Errors**: Check Terraform state and backend configuration
- **Approval Timeout**: Approvers have unlimited time to respond

### Security Notes
- All operations use the same security measures as automated workflows
- Database passwords are still retrieved from GitHub Secrets
- AWS credentials use OIDC authentication
- All actions are logged and auditable

### Workflow Permissions
Only users with the following permissions can trigger manual workflows:
- Repository admin
- Users with "Actions" write permissions
- Users explicitly granted workflow permissions

For questions or issues with manual workflows, please create a GitHub issue.