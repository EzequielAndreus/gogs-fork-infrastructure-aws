# GitHub Actions CI Credentials

This document outlines all credentials and secrets required for the **Continuous Integration (CI) pipeline** running on GitHub Actions. **Never commit actual credentials to version control.**

## 📋 Table of Contents

1. [Overview](#-overview)
2. [AWS Credentials](#-aws-credentials)
3. [GitHub Actions Secrets](#-github-actions-secrets)
4. [Terraform Variables](#-terraform-variables)
5. [Security Best Practices](#️-security-best-practices)
6. [Secret Rotation](#-secret-rotation)
7. [Troubleshooting](#-troubleshooting)

---

## 🎯 Overview

The GitHub Actions CI pipeline performs:
- ✅ Terraform format checking
- ✅ Terraform validation
- ✅ TFLint (linting)
- ✅ Checkov security scanning
- ✅ Terragrunt validation for staging and production
- ✅ Terraform plan generation (on PRs)
- ✅ Documentation checks

**Backend:** Terraform Cloud is used to track infrastructure state instead of S3/DynamoDB.

**Pipeline Trigger:** Push to `main` or `feature/**` branches, and Pull Requests to `main`

---

## 🔐 AWS Credentials

### Required IAM Permissions

Create an IAM user or role with the following permissions for CI validation and planning:

**Note:** Since Terraform Cloud is used as the backend, S3 and DynamoDB permissions for state management are not required.

#### Option 1: Managed Policies (Broader permissions)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ecs:Describe*",
        "ecs:List*",
        "rds:Describe*",
        "secretsmanager:Describe*",
        "secretsmanager:List*",
        "elasticloadbalancing:Describe*",
        "cloudwatch:Describe*",
        "logs:Describe*",
        "iam:Get*",
        "iam:List*",
        "kms:Describe*",
        "kms:List*",
        "autoscaling:Describe*",
        "application-autoscaling:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Option 2: Custom Policy (Recommended - Least Privilege)

Create a policy for CI validation (read-only infrastructure access):

<details>
<summary>Click to expand custom IAM policy</summary>

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadOnlyInfrastructure",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ecs:Describe*",
        "ecs:List*",
        "rds:Describe*",
        "rds:List*",
        "secretsmanager:Describe*",
        "secretsmanager:List*",
        "secretsmanager:GetResourcePolicy",
        "elasticloadbalancing:Describe*",
        "cloudwatch:Describe*",
        "cloudwatch:List*",
        "logs:Describe*",
        "logs:List*",
        "iam:GetRole",
        "iam:GetRolePolicy",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListRoles",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:ListInstanceProfiles",
        "kms:DescribeKey",
        "kms:GetKeyPolicy",
        "kms:ListAliases",
        "kms:ListKeys",
        "autoscaling:Describe*",
        "application-autoscaling:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
```

</details>

### Creating AWS Credentials for CI

1. **Create IAM User:**
   ```bash
   aws iam create-user --user-name github-actions-ci
   ```

2. **Attach Policy:**
   ```bash
   aws iam attach-user-policy \
     --user-name github-actions-ci \
     --policy-arn arn:aws:iam::YOUR_ACCOUNT:policy/GitHubActionsCIPolicy
   ```

3. **Create Access Keys:**
   ```bash
   aws iam create-access-key --user-name github-actions-ci
   ```

   **Save the output securely!**

---

## 🐙 GitHub Actions Secrets

Navigate to your repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

### Required Secrets

| Secret Name | Description | Used In | Example |
|-------------|-------------|---------|---------|| `TF_API_TOKEN` | Terraform Cloud API token for backend authentication | All Terraform/Terragrunt jobs | `xxxxxxxxxx.atlasv1.zzzzzzzzzzzzz...` || `AWS_ACCESS_KEY_ID` | AWS access key for CI | All validation/plan jobs | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for CI | All validation/plan jobs | `wJalrXUtnFEMI/...` |
| `DB_USERNAME` | RDS database master username | Terragrunt plan | `admin` |
| `DB_PASSWORD` | RDS database master password | Terragrunt plan | `MySecurePassword123!` |
| `SPLUNK_ADMIN_PASSWORD` | Splunk administrator password | Terragrunt plan | `SplunkAdmin123!` |
| `APP_SECRET_KEY` | Application secret key | Terragrunt plan | `your-256-bit-secret-key` |
| `SPLUNK_HEC_TOKEN` | Splunk HTTP Event Collector token | Terragrunt plan | `12345678-1234-...` |
| `DOCKER_IMAGE` | Docker image to deploy | Terragrunt plan | `username/app:latest` |

### Secrets Usage by Job

| Job | Secrets Used |
| ----- | ------------ |
| `terraform-fmt` | None |
| `terraform-validate` | None |
| `tflint` | None |
| `checkov` | None |
| `terragrunt-validate-staging` | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` |
| `terragrunt-validate-production` | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` |
| `terragrunt-plan-staging` (PR only) | All secrets |
| `docs-check` | None |

### Setting Up Secrets via GitHub CLI

```bash
# Install GitHub CLI if not present
# https://cli.github.com/

# Login to GitHub
gh auth login

# Set Terraform Cloud token (get from <https://app.terraform.io/app/settings/tokens>)
gh secret set TF_API_TOKEN --body "xxxxxxxxxx.atlasv1.zzzzzzzzzzzzz..."

# Set CI secrets
gh secret set AWS_ACCESS_KEY_ID --body "AKIAIOSFODNN7EXAMPLE"
gh secret set AWS_SECRET_ACCESS_KEY --body "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
gh secret set DB_USERNAME --body "admin"
gh secret set DB_PASSWORD --body "MySecurePassword123!"
gh secret set SPLUNK_ADMIN_PASSWORD --body "SplunkAdmin123!"
gh secret set APP_SECRET_KEY --body "your-256-bit-secret-key"
gh secret set SPLUNK_HEC_TOKEN --body "12345678-1234-1234-1234-123456789012"
gh secret set DOCKER_IMAGE --body "username/app:latest"
```

### Setting Up Secrets via GitHub UI

1. Navigate to repository → **Settings**
2. Click **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. **First, add Terraform Cloud token:**
   - **Name**: `TF_API_TOKEN`
   - **Secret**: Your Terraform Cloud API token (from https://app.terraform.io/app/settings/tokens)
5. Click **Add secret**
6. **Then, add AWS credentials:**
   - **Name**: `AWS_ACCESS_KEY_ID`
   - **Secret**: Your AWS access key
7. Click **Add secret**
8. Repeat for all other secrets

---

## 📝 Terraform Variables

These environment variables are used during Terragrunt validation and planning:

| Variable | Description | Required | Used In |
| ---------- | ------------- | ---------- | --------- |
| `TF_VAR_db_username` | Database master username | ✅ | Plan job |
| `TF_VAR_db_password` | Database master password | ✅ | Plan job |
| `TF_VAR_splunk_admin_password` | Splunk admin password | ✅ | Plan job |
| `TF_VAR_app_secret_key` | Application secret | ✅ | Plan job |
| `TF_VAR_splunk_hec_token` | Splunk HEC token | ✅ | Plan job |
| `TF_VAR_docker_image` | Docker image URI | ✅ | Plan job |

**Note:** For validation jobs, mock values are used (e.g., `test_user`, `test_password`). Real secrets are only used in the plan job for PRs.

---

## ⚠️ Security Best Practices

### GitHub Actions Specific

1. **Use environment protection rules** for production secrets
2. **Enable branch protection** on `main` branch
3. **Require PR reviews** before merging
4. **Use CODEOWNERS** for sensitive file changes
5. **Enable "Require approval for all outside collaborators"**
6. **Review GitHub Actions audit log** regularly
7. **Use least privilege** AWS credentials (read-only + state access)
8. **Never log secrets** in workflow output
9. **Use `secrets` context** instead of environment variables when possible
10. **Rotate secrets** periodically (see rotation schedule below)

### GitHub Repository Settings

```bash
# Enable required reviews
gh repo edit --enable-required-reviews

# Enable branch protection
gh api repos/:owner/:repo/branches/main/protection \
  -X PUT \
  -H "Accept: application/vnd.github.v3+json" \
  --input protection.json
```

Example `protection.json`:
```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["terraform-fmt", "terraform-validate", "checkov"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "restrictions": null
}
```

---

## 🔄 Secret Rotation

### Password Requirements

| Secret | Minimum Length | Requirements |
| -------- | --------------- | -------------- |
| `DB_PASSWORD` | 16 characters | Uppercase, lowercase, numbers, special chars |
| `SPLUNK_ADMIN_PASSWORD` | 12 characters | Uppercase, lowercase, numbers |
| `APP_SECRET_KEY` | 32 characters | Random alphanumeric |

### Rotation Schedule

| Secret | Rotation Frequency | Impact |
| -------- | ------------------- | -------- |
| Terraform Cloud API Token | Every 90 days | Update in GitHub secrets |
| AWS Access Keys | Every 90 days | Update in GitHub secrets |
| Database Password | Every 90 days | Update in GitHub secrets + Trigger redeployment |
| Splunk Password | Every 90 days | Update in GitHub secrets + Trigger redeployment |
| App Secret Key | As needed | Update in GitHub secrets + Trigger redeployment |
| Docker Image Tag | Every deployment | Update in GitHub secrets |

### Rotating AWS Credentials

```bash
# 1. Create new access key
aws iam create-access-key --user-name github-actions-ci

# 2. Update GitHub secret
gh secret set AWS_ACCESS_KEY_ID --body "NEW_ACCESS_KEY_ID"
gh secret set AWS_SECRET_ACCESS_KEY --body "NEW_SECRET_ACCESS_KEY"

# 3. Test the new credentials (trigger a workflow)

# 4. Deactivate old access key
aws iam update-access-key \
  --user-name github-actions-ci \
  --access-key-id OLD_ACCESS_KEY_ID \
  --status Inactive

# 5. After verification, delete old key
aws iam delete-access-key \
  --user-name github-actions-ci \
  --access-key-id OLD_ACCESS_KEY_ID
```

### Rotating Terraform Cloud Token

```bash
# 1. Generate new token in Terraform Cloud
#    Visit: https://app.terraform.io/app/settings/tokens
#    Click "Create an API token"

# 2. Update GitHub secret
gh secret set TF_API_TOKEN --body "NEW_TERRAFORM_CLOUD_TOKEN"

# 3. Test the new token (trigger a workflow)

# 4. Revoke old token in Terraform Cloud UI
```

### Rotating Other Secrets

1. **Generate new secret value**
2. **Update in GitHub Actions secrets:**
   ```bash
   gh secret set SECRET_NAME --body "NEW_VALUE"
   ```
3. **Trigger workflow** to test
4. **Update in Jenkins** (see JENKINS-CREDENTIALS.md)
5. **Revoke/delete** old secret

---

## 🆘 Troubleshooting

### Common Issues

| Issue | Cause | Solution |
| ------- | ------- | ---------- |
| "Authentication failed" | Invalid AWS credentials | Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` |
| "Access Denied" during plan | Missing IAM permissions | Check IAM policy includes `Describe*` permissions |
| "Secret not found" | Typo in secret name | Verify secret name matches workflow exactly |
| "Terraform init failed" | Missing TF_API_TOKEN or invalid Terraform Cloud workspace | Verify `TF_API_TOKEN` is set and workspace exists in Terraform Cloud |
| Plan hangs on PR | Secret value contains special chars | Properly escape or quote secret values |

### Verifying Credentials Locally

```bash
# Set AWS credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"

# Set Terraform Cloud token
export TF_TOKEN_app_terraform_io="your-terraform-cloud-token"
# OR create ~/.terraform.d/credentials.tfrc.json with:
# {
#   "credentials": {
#     "app.terraform.io": {
#       "token": "your-terraform-cloud-token"
#     }
#   }
# }

# Test AWS credentials
aws sts get-caller-identity

# Test Terraform Cloud authentication
terraform login

# Test Terragrunt validate locally
cd environments/us-east-1/staging
export TF_VAR_db_username="test"
export TF_VAR_db_password="test"
export TF_VAR_splunk_admin_password="test"
export TF_VAR_app_secret_key="test"
export TF_VAR_splunk_hec_token="test"
export TF_VAR_docker_image="nginx:latest"
terragrunt run-all validate
```

### Debugging GitHub Actions Workflow

```bash
# View workflow runs
gh run list --workflow=ci.yml

# View specific run logs
gh run view <run-id> --log

# Re-run failed jobs
gh run rerun <run-id> --failed

# Enable debug logging (add these secrets)
gh secret set ACTIONS_STEP_DEBUG --body "true"
gh secret set ACTIONS_RUNNER_DEBUG --body "true"
```

### Checking IAM Policy Simulation

```bash
# Simulate policy for EC2 describe
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT:user/github-actions-ci \
  --action-names ec2:DescribeVpcs \
  --resource-arns "*"

# Simulate RDS describe
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT:user/github-actions-ci \
  --action-names rds:DescribeDBInstances \
  --resource-arns "*"
```

---

## 📊 CI Pipeline Flow

```mermaid
graph TD
    A[Push/PR to main] --> B[terraform-fmt]
    B --> C{Format Check}
    C -->|Pass| D[terraform-validate]
    C -->|Fail| Z[CI Failed]
    D --> E[tflint]
    D --> F[checkov]
    E --> G[terragrunt-validate-staging]
    E --> H[terragrunt-validate-production]
    F --> G
    F --> H
    G --> I{Is PR?}
    I -->|Yes| J[terragrunt-plan-staging]
    I -->|No| K[docs-check]
    H --> K
    J --> K
    K --> L[ci-summary]
    L --> M[CI Success]
```

---

## 📚 References

- [GitHub Actions Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub Actions Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform AWS Provider Authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)
- [GitHub CLI Documentation](https://cli.github.com/manual/)

---

## 📞 Support

- **GitHub Actions Issues**: Check workflow logs and [GitHub Status](https://www.githubstatus.com/)
- **AWS IAM Issues**: Review IAM policy and use policy simulator
- **Terraform Issues**: Verify Terraform and Terragrunt versions match requirements

**Related Documentation:**
- [JENKINS-CREDENTIALS.md](JENKINS-CREDENTIALS.md) - CD pipeline credentials
- [README.md](README.md) - Project overview
- [MODULES.md](MODULES.md) - Terraform modules documentation
