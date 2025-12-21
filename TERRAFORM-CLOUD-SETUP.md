# Terraform Cloud Authentication Setup

This document explains how to authenticate with Terraform Cloud for managing remote state.

## Prerequisites

1. **Terraform Cloud Account**: Sign up at [https://app.terraform.io](https://app.terraform.io)
2. **Organization**: Create an organization in Terraform Cloud
3. **API Token**: Generate a user or team API token

## Authentication Methods

### Method 1: Using `.terraformrc` file (Recommended for Local Development)

Create or edit the `.terraformrc` file in your home directory:

```bash
# Linux/macOS
nano ~/.terraformrc

# Windows
notepad %APPDATA%\terraform.rc
```

Add the following content:

```hcl
credentials "app.terraform.io" {
  token = "YOUR_TERRAFORM_CLOUD_API_TOKEN"
}
```

**Security Note**: Never commit this file to version control! It's automatically gitignored.

### Method 2: Using Environment Variables (Recommended for CI/CD)

Set the Terraform Cloud token as an environment variable:

```bash
# Linux/macOS
export TF_TOKEN_app_terraform_io="YOUR_TERRAFORM_CLOUD_API_TOKEN"

# Windows PowerShell
$env:TF_TOKEN_app_terraform_io="YOUR_TERRAFORM_CLOUD_API_TOKEN"

# Windows CMD
set TF_TOKEN_app_terraform_io=YOUR_TERRAFORM_CLOUD_API_TOKEN
```

For persistent configuration, add to your shell profile:

```bash
# Add to ~/.bashrc or ~/.zshrc
echo 'export TF_TOKEN_app_terraform_io="YOUR_TERRAFORM_CLOUD_API_TOKEN"' >> ~/.bashrc
source ~/.bashrc
```

### Method 3: Using `terraform login` Command

Run the interactive login command:

```bash
terraform login
```

This will open a browser window to generate and store a token automatically.

## Required Environment Variables

### Terraform Cloud Configuration

```bash
# Organization name in Terraform Cloud
export TF_CLOUD_ORGANIZATION="your-organization-name"
```

### AWS Account Configuration

```bash
# AWS Account ID (prevents hardcoding)
export TF_VAR_aws_account_id="123456789012"
```

### Application Secrets (for deployment)

```bash
# Database credentials
export TF_VAR_db_username="your_db_admin"
export TF_VAR_db_password="your_secure_password"

# Application secrets
export TF_VAR_app_secret_key="your_app_secret_key"

# Splunk credentials (if using)
export TF_VAR_splunk_admin_password="your_splunk_password"
export TF_VAR_splunk_hec_token="your_hec_token"

# SSH access (optional)
export TF_VAR_ssh_public_key="ssh-rsa AAAAB3NzaC1yc2E..."
export TF_VAR_ssh_cidr="10.0.0.0/8"
export TF_VAR_allowed_cidr="10.0.0.0/8"

# AMI ID (optional, has defaults)
export TF_VAR_splunk_ami_id="ami-0c7217cdde317cfec"
```

## CI/CD Setup

### GitHub Actions

Add secrets to your GitHub repository settings:

1. Go to: `Settings` → `Secrets and variables` → `Actions`
2. Add the following secrets:
   - `TF_CLOUD_ORGANIZATION`
   - `TF_API_TOKEN` (Terraform Cloud API token)
   - `AWS_ACCOUNT_ID`
   - `DB_USERNAME`
   - `DB_PASSWORD`
   - `APP_SECRET_KEY`
   - `SPLUNK_ADMIN_PASSWORD` (if using)
   - `SPLUNK_HEC_TOKEN` (if using)

### Jenkins

Add credentials in Jenkins:

1. Go to: `Manage Jenkins` → `Credentials`
2. Add secrets as "Secret text" or "Username with password"
3. Reference them in your Jenkinsfile using the `credentials()` helper

## Workspace Configuration

Terraform Cloud workspaces are automatically named using the pattern:

```
<project>-<environment>-<region>-<module>
```

Examples:
- `gogs-fork-production-us-east-1-vpc`
- `gogs-fork-staging-us-east-1-ecs`
- `gogs-fork-production-us-east-1-rds`

## Workspace Settings in Terraform Cloud

For each workspace, configure:

1. **Execution Mode**: Choose "Local" or "Remote"
   - Local: Runs on your machine/CI server
   - Remote: Runs in Terraform Cloud

2. **Terraform Version**: Set to `>= 1.5.0`

3. **Environment Variables**: Add in workspace settings:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_SESSION_TOKEN` (if using temporary credentials)

4. **Terraform Variables**: Add sensitive variables in workspace settings:
   - Mark as "Sensitive" to hide values
   - Alternatively, use environment variables with `TF_VAR_` prefix

## Security Best Practices

1. **Never commit tokens or credentials** to version control
2. **Use environment variables** for all sensitive data
3. **Rotate tokens regularly** (every 90 days recommended)
4. **Use team tokens** instead of user tokens for CI/CD
5. **Enable MFA** on your Terraform Cloud account
6. **Audit workspace access** regularly
7. **Use separate organizations** for production and non-production

## Troubleshooting

### "No valid credential sources found"

- Verify your token is set correctly
- Check `.terraformrc` file location and content
- Try `terraform login` to regenerate token

### "Organization not found"

- Verify `TF_CLOUD_ORGANIZATION` environment variable is set
- Check organization name spelling in Terraform Cloud

### "Workspace not found"

- Workspaces are created automatically on first run
- Verify naming pattern matches your module path
- Check organization permissions

## Additional Resources

- [Terraform Cloud Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [CLI Configuration](https://developer.hashicorp.com/terraform/cli/config/config-file)
- [Environment Variables](https://developer.hashicorp.com/terraform/cli/config/environment-variables)
