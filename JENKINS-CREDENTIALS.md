# Jenkins CD Credentials

This document outlines all credentials and secrets required for the **Continuous Deployment (CD) pipeline** running on Jenkins. **Never commit actual credentials to version control.**

## 📋 Table of Contents

1. [Overview](#overview)
2. [AWS Credentials](#aws-credentials)
3. [Jenkins Credentials](#jenkins-credentials)
4. [Discord Webhook Configuration](#discord-webhook-configuration)
5. [Jira API Configuration](#jira-api-configuration)
6. [Terraform Variables](#terraform-variables)
7. [Security Best Practices](#security-best-practices)
8. [Secret Rotation](#secret-rotation)
9. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

The Jenkins CD pipeline performs:
- 🚀 Automatic infrastructure provisioning/updates based on plan detection
- 🔄 Staging and production deployment with conditional logic
- ✅ Manual approval requirement for production changes
- 📢 Discord notifications for pipeline events
- 🎫 Automatic Jira ticket creation on failures

**Pipeline Trigger:** Manual or automated (webhook/SCM polling)

**Key Features:**
- No manual parameter selection required
- Automatic change detection via Terragrunt plan
- Environment-specific credential mapping
- Discord notifications at each stage
- Production approval gate

---

## 🔐 AWS Credentials

### Required IAM Permissions

Jenkins requires **full infrastructure management** permissions for both staging and production environments.

#### Option 1: Managed Policies (Broader permissions)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "ecs:*",
        "rds:*",
        "secretsmanager:*",
        "elasticloadbalancing:*",
        "cloudwatch:*",
        "logs:*",
        "iam:*",
        "kms:*",
        "s3:*",
        "dynamodb:*",
        "autoscaling:*",
        "application-autoscaling:*"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Option 2: Custom Policy (Recommended - Least Privilege)

Create separate policies for each service and attach to the IAM user/role:

<details>
<summary>Click to expand custom IAM policy</summary>

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VPCManagement",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:DescribeVpcs",
        "ec2:ModifyVpcAttribute",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:DescribeSubnets",
        "ec2:CreateInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:DescribeInternetGateways",
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway",
        "ec2:DescribeNatGateways",
        "ec2:AllocateAddress",
        "ec2:ReleaseAddress",
        "ec2:DescribeAddresses",
        "ec2:CreateRouteTable",
        "ec2:DeleteRouteTable",
        "ec2:DescribeRouteTables",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeSecurityGroups",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EC2Management",
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:DescribeInstances",
        "ec2:CreateVolume",
        "ec2:DeleteVolume",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:DescribeVolumes",
        "ec2:CreateKeyPair",
        "ec2:DeleteKeyPair",
        "ec2:DescribeKeyPairs",
        "ec2:DescribeImages",
        "ec2:DescribeAvailabilityZones",
        "ec2:ModifyInstanceAttribute"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECSManagement",
      "Effect": "Allow",
      "Action": [
        "ecs:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "RDSManagement",
      "Effect": "Allow",
      "Action": [
        "rds:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SecretsManagerManagement",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:TagRole",
        "iam:UntagRole"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KMSManagement",
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey",
        "kms:CreateAlias",
        "kms:DeleteAlias",
        "kms:DescribeKey",
        "kms:GetKeyPolicy",
        "kms:PutKeyPolicy",
        "kms:ScheduleKeyDeletion",
        "kms:EnableKeyRotation",
        "kms:ListAliases",
        "kms:TagResource",
        "kms:UntagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "LoadBalancerManagement",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchManagement",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:*",
        "logs:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AutoScalingManagement",
      "Effect": "Allow",
      "Action": [
        "autoscaling:*",
        "application-autoscaling:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformStateManagement",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "arn:aws:s3:::gogs-app-terraform-state-*",
        "arn:aws:s3:::gogs-app-terraform-state-*/*"
      ]
    },
    {
      "Sid": "TerraformStateLocking",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/gogs-app-terraform-locks"
    }
  ]
}
```

</details>

### Creating AWS Credentials for Jenkins

#### Staging Environment

```bash
# Create IAM user
aws iam create-user --user-name jenkins-cd-staging

# Attach policy
aws iam attach-user-policy \
  --user-name jenkins-cd-staging \
  --policy-arn arn:aws:iam::YOUR_ACCOUNT:policy/JenkinsCDPolicy

# Create access key
aws iam create-access-key --user-name jenkins-cd-staging
```

#### Production Environment

```bash
# Create IAM user
aws iam create-user --user-name jenkins-cd-production

# Attach policy
aws iam attach-user-policy \
  --user-name jenkins-cd-production \
  --policy-arn arn:aws:iam::YOUR_ACCOUNT:policy/JenkinsCDPolicy

# Create access key
aws iam create-access-key --user-name jenkins-cd-production
```

**Save both outputs securely!**

---

## 🔧 Jenkins Credentials

Navigate to Jenkins → **Manage Jenkins** → **Manage Credentials** → **System** → **Global credentials**

### Required Credentials

| Credential ID | Type | Description | Environment |
|---------------|------|-------------|-------------|
| `aws-infrastructure-credentials` | Username with password | AWS Access Key (username) and Secret Key (password) | Staging |
| `aws-infrastructure-credentials-prod` | Username with password | AWS Access Key (username) and Secret Key (password) | Production |
| `discord-webhook-staging` | Secret text | Discord webhook URL for staging notifications | Staging |
| `discord-webhook-production` | Secret text | Discord webhook URL for production notifications | Production |
| `jira-credentials` | Username with password | Jira email (username) and API token (password) | Both |
| `db-username-staging` | Secret text | RDS database master username | Staging |
| `db-password-staging` | Secret text | RDS database master password | Staging |
| `db-username-production` | Secret text | RDS database master username | Production |
| `db-password-production` | Secret text | RDS database master password | Production |
| `splunk-admin-password-staging` | Secret text | Splunk administrator password | Staging |
| `splunk-admin-password-production` | Secret text | Splunk administrator password | Production |
| `app-secret-key-staging` | Secret text | Application secret key | Staging |
| `app-secret-key-production` | Secret text | Application secret key | Production |
| `splunk-hec-token-staging` | Secret text | Splunk HTTP Event Collector token | Staging |
| `splunk-hec-token-production` | Secret text | Splunk HTTP Event Collector token | Production |
| `docker-image-staging` | Secret text | Docker image to deploy | Staging |
| `docker-image-production` | Secret text | Docker image to deploy | Production |

### How Credentials Are Used in Jenkinsfile

All credentials are defined in the global `environment` block using the `credentials()` function:

```groovy
environment {
    // AWS Credentials
    AWS_CREDS_STAGING = credentials('aws-infrastructure-credentials')
    AWS_CREDS_PRODUCTION = credentials('aws-infrastructure-credentials-prod')
    
    // Discord Webhooks
    DISCORD_WEBHOOK_STAGING = credentials('discord-webhook-staging')
    DISCORD_WEBHOOK_PRODUCTION = credentials('discord-webhook-production')
    
    // Jira
    JIRA_CREDS = credentials('jira-credentials')
    
    // Terraform Variables - Staging
    TF_VAR_db_username_staging = credentials('db-username-staging')
    TF_VAR_db_password_staging = credentials('db-password-staging')
    // ... etc
}
```

At the stage level, credentials are mapped to standard variable names:

```groovy
stage('Staging') {
    environment {
        AWS_ACCESS_KEY_ID = "${AWS_CREDS_STAGING_USR}"
        AWS_SECRET_ACCESS_KEY = "${AWS_CREDS_STAGING_PSW}"
        TF_VAR_db_username = "${TF_VAR_db_username_staging}"
        // ... etc
    }
}
```

### Setting Up Jenkins Credentials

#### Via Jenkins UI:

1. **AWS Credentials (Username with password):**
   - Go to: Manage Jenkins → Manage Credentials → System → Global credentials → Add Credentials
   - Kind: `Username with password`
   - Scope: `Global`
   - ID: `aws-infrastructure-credentials`
   - Username: Your AWS Access Key ID (e.g., `AKIAIOSFODNN7EXAMPLE`)
   - Password: Your AWS Secret Access Key
   - Description: `AWS credentials for staging infrastructure`
   - Click **OK**

2. **Discord Webhook (Secret text):**
   - Kind: `Secret text`
   - Scope: `Global`
   - Secret: The Discord webhook URL
   - ID: `discord-webhook-staging` or `discord-webhook-production`
   - Description: `Discord webhook for staging/production notifications`
   - Click **OK**

3. **Jira Credentials (Username with password):**
   - Kind: `Username with password`
   - Scope: `Global`
   - ID: `jira-credentials`
   - Username: Your Jira email address (e.g., `your.email@company.com`)
   - Password: Your Jira API token
   - Description: `Jira API credentials for ticket creation`
   - Click **OK**

4. **Database Credentials (Secret text):**
   - Kind: `Secret text`
   - Scope: `Global`
   - Secret: The database username or password
   - ID: `db-username-staging`, `db-password-staging`, etc.
   - Description: `Database credentials for [environment]`
   - Click **OK**

#### Via Jenkins CLI:

```bash
# Download Jenkins CLI
wget http://your-jenkins-url/jnlpJars/jenkins-cli.jar

# Create AWS credentials (staging)
cat << 'EOF' > aws-staging-cred.xml
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>aws-infrastructure-credentials</id>
  <description>AWS credentials for staging infrastructure</description>
  <username>AKIAIOSFODNN7STAGING</username>
  <password>staging-secret-access-key</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF

java -jar jenkins-cli.jar -s http://your-jenkins-url/ \
  -auth admin:admin_token \
  create-credentials-by-xml system::system::jenkins \
  < aws-staging-cred.xml

# Create secret text credential
cat << 'EOF' > discord-webhook.xml
<org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>discord-webhook-staging</id>
  <description>Discord webhook for staging</description>
  <secret>https://discord.com/api/webhooks/...</secret>
</org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
EOF

java -jar jenkins-cli.jar -s http://your-jenkins-url/ \
  -auth admin:admin_token \
  create-credentials-by-xml system::system::jenkins \
  < discord-webhook.xml
```

#### Via Groovy Script (Jenkins Console):

Navigate to Jenkins → **Manage Jenkins** → **Script Console**

```groovy
import jenkins.model.Jenkins
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.domains.*
import org.jenkinsci.plugins.plaincredentials.impl.*

// Get credentials store
def store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// Create AWS credentials (username/password)
def awsCreds = new UsernamePasswordCredentialsImpl(
  CredentialsScope.GLOBAL,
  "aws-infrastructure-credentials",
  "AWS credentials for staging",
  "AKIAIOSFODNN7STAGING",
  "staging-secret-access-key"
)
store.addCredentials(Domain.global(), awsCreds)

// Create Discord webhook (secret text)
def discordWebhook = new StringCredentialsImpl(
  CredentialsScope.GLOBAL,
  "discord-webhook-staging",
  "Discord webhook for staging",
  hudson.util.Secret.fromString("https://discord.com/api/webhooks/...")
)
store.addCredentials(Domain.global(), discordWebhook)

println("Credentials created successfully!")
```

### Jenkins Plugins Required

Ensure these plugins are installed:
- **Credentials Plugin** (credentials)
- **Credentials Binding Plugin** (credentials-binding)
- **Plain Credentials Plugin** (plain-credentials)
- **AWS Credentials Plugin** (aws-credentials) - Optional but recommended
- **Pipeline: AWS Steps** (pipeline-aws) - Optional

To install plugins:
```bash
# Via Jenkins CLI
java -jar jenkins-cli.jar -s http://your-jenkins-url/ \
  -auth admin:admin_token \
  install-plugin credentials credentials-binding plain-credentials

# Restart Jenkins
java -jar jenkins-cli.jar -s http://your-jenkins-url/ \
  -auth admin:admin_token \
  safe-restart
```

---

## 🔔 Discord Webhook Configuration

Discord webhooks send real-time pipeline notifications to designated channels.

### Creating a Discord Webhook

1. **Open Discord Server Settings:**
   - Navigate to your Discord server
   - Click on **Server Settings** → **Integrations** → **Webhooks**

2. **Create New Webhook:**
   - Click **"New Webhook"** or **"Create Webhook"**
   - **Name**: `Jenkins-Staging` or `Jenkins-Production`
   - **Channel**: Select the channel (e.g., `#infrastructure-staging`, `#infrastructure-production`)
   - Click **"Copy Webhook URL"**
   - Click **"Save Changes"**

3. **Add to Jenkins:**
   - Go to: Manage Jenkins → Manage Credentials → System → Global credentials
   - Click **"Add Credentials"**
   - Kind: `Secret text`
   - Secret: Paste the webhook URL
   - ID: `discord-webhook-staging` or `discord-webhook-production`
   - Description: `Discord webhook for [environment] notifications`
   - Click **OK**

### Webhook URL Format

```
https://discord.com/api/webhooks/{webhook_id}/{webhook_token}
```

Example:
```
https://discord.com/api/webhooks/123456789012345678/AbCdEfGhIjKlMnOpQrStUvWxYz1234567890AbCdEfGhIjKlMnOpQr
```

### Recommended Channel Setup

| Channel | Purpose | Credential ID | Notifications |
|---------|---------|---------------|---------------|
| `#infrastructure-staging` | Staging deployments | `discord-webhook-staging` | Plan, Apply start, Success, Failure |
| `#infrastructure-production` | Production deployments | `discord-webhook-production` | Approval required, Apply start, Success, Failure |
| `#infrastructure-alerts` | Critical alerts (optional) | `discord-webhook-alerts` | Production failures only |

### Discord Notification Types

The pipeline sends these notification types:

| Status | Color | Emoji | When Triggered |
|--------|-------|-------|----------------|
| `STARTED` | Blue | 🚀 | Before apply starts |
| `SUCCESS` | Green | ✅ | After successful apply |
| `FAILURE` | Red | ❌ | On pipeline failure |
| `APPROVAL_REQUIRED` | Yellow | ⏳ | Production changes detected |

### Security Considerations

- **Keep webhook URLs secret** - Anyone with the URL can post to your channel
- **Use separate webhooks** for staging and production
- **Regularly rotate** webhook URLs if compromised (delete and create new)
- **Limit webhook permissions** using Discord channel permissions
- **Monitor webhook usage** in Discord Server Settings → Integrations

---

## 🎫 Jira API Configuration

Jira integration enables automatic ticket creation when pipeline failures occur.

### Creating a Jira API Token

1. **Navigate to Atlassian Account Settings:**
   - Go to: https://id.atlassian.com/manage-profile/security/api-tokens

2. **Create API Token:**
   - Click **"Create API token"**
   - Label: `Jenkins Infrastructure CD Pipeline`
   - Click **"Create"**
   - **Copy the token immediately** (it won't be shown again!)

3. **Add to Jenkins:**
   - Go to: Manage Jenkins → Manage Credentials → System → Global credentials
   - Click **"Add Credentials"**
   - Kind: `Username with password`
   - Username: Your Jira account email (e.g., `your.email@company.com`)
   - Password: The API token you just created
   - ID: `jira-credentials`
   - Description: `Jira API credentials for ticket creation`
   - Click **OK**

### Jenkinsfile Configuration

Set these in your Jenkinsfile environment block (already configured):

```groovy
environment {
    JIRA_URL = 'https://your-company.atlassian.net'
    JIRA_PROJECT_KEY = 'INFRA'
    JIRA_CREDS = credentials('jira-credentials')
}
```

Update these values:
- `JIRA_URL`: Your Jira instance URL
- `JIRA_PROJECT_KEY`: Project key for infrastructure tickets (e.g., `INFRA`, `OPS`, `DEVOPS`)

### Jira Project Setup

1. **Create or use existing project:**
   - Go to Jira → **Projects** → **Create project**
   - Template: **Kanban** or **Scrum**
   - Name: `Infrastructure`
   - Key: `INFRA`

2. **Configure Issue Types:**
   - Ensure **"Bug"** issue type is available
   - The pipeline creates tickets as "Bug" type by default

3. **Set up priorities:**
   - Ensure these priorities exist:
     - **Critical** - Used for production failures
     - **High** - Used for staging failures

4. **Create custom labels (optional):**
   - `infrastructure`
   - `terraform`
   - `auto-created`
   - `staging` / `production`

### Required Jira Permissions

The API token user needs these permissions:

| Permission | Purpose |
|------------|---------|
| **Browse Projects** | View project details |
| **Create Issues** | Create new tickets on failures |
| **Assign Issues** (optional) | Auto-assign tickets |
| **Transition Issues** (optional) | Change ticket status |
| **Add Comments** (optional) | Add updates to tickets |

### Jira API Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/rest/api/2/issue` | POST | Create new issue |

### Sample Jira Ticket Created on Failure

```json
{
  "fields": {
    "project": {
      "key": "INFRA"
    },
    "summary": "Infrastructure apply Failed - PRODUCTION",
    "description": "Infrastructure Pipeline Failure\n\nEnvironment: production\nAction: apply\nModule: all\nBuild URL: http://jenkins.example.com/job/infrastructure/123\n\nError Details:\nError: Error creating RDS instance: ...\n\nNext Steps:\n1. Review the Jenkins build logs\n2. Identify the root cause\n3. Fix the issue and re-run the pipeline",
    "issuetype": {
      "name": "Bug"
    },
    "priority": {
      "name": "Critical"
    },
    "labels": ["infrastructure", "terraform", "production", "auto-created"]
  }
}
```

### Testing Jira Integration

```bash
# Test Jira API connection
curl -u "your.email@company.com:your-api-token" \
  -X GET \
  -H "Content-Type: application/json" \
  https://your-company.atlassian.net/rest/api/2/myself

# Test creating an issue
curl -u "your.email@company.com:your-api-token" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "project": {"key": "INFRA"},
      "summary": "Test ticket from Jenkins",
      "description": "Test description",
      "issuetype": {"name": "Bug"}
    }
  }' \
  https://your-company.atlassian.net/rest/api/2/issue
```

---

## 📝 Terraform Variables

These environment variables are mapped from Jenkins credentials and used by Terragrunt during plan/apply:

### Staging Environment Variables

| Variable | Credential ID | Description |
|----------|---------------|-------------|
| `TF_VAR_db_username` | `db-username-staging` | Database master username |
| `TF_VAR_db_password` | `db-password-staging` | Database master password |
| `TF_VAR_splunk_admin_password` | `splunk-admin-password-staging` | Splunk admin password |
| `TF_VAR_app_secret_key` | `app-secret-key-staging` | Application secret key |
| `TF_VAR_splunk_hec_token` | `splunk-hec-token-staging` | Splunk HEC token |
| `TF_VAR_docker_image` | `docker-image-staging` | Docker image URI |

### Production Environment Variables

| Variable | Credential ID | Description |
|----------|---------------|-------------|
| `TF_VAR_db_username` | `db-username-production` | Database master username |
| `TF_VAR_db_password` | `db-password-production` | Database master password |
| `TF_VAR_splunk_admin_password` | `splunk-admin-password-production` | Splunk admin password |
| `TF_VAR_app_secret_key` | `app-secret-key-production` | Application secret key |
| `TF_VAR_splunk_hec_token` | `splunk-hec-token-production` | Splunk HEC token |
| `TF_VAR_docker_image` | `docker-image-production` | Docker image URI |

### How Variables Are Mapped

In the Jenkinsfile, credentials are bound to environment-specific variables:

```groovy
stage('Staging') {
    environment {
        // Map staging-specific credentials
        TF_VAR_db_username = "${TF_VAR_db_username_staging}"
        TF_VAR_db_password = "${TF_VAR_db_password_staging}"
        // ... etc
    }
}

stage('Production') {
    environment {
        // Map production-specific credentials
        TF_VAR_db_username = "${TF_VAR_db_username_production}"
        TF_VAR_db_password = "${TF_VAR_db_password_production}"
        // ... etc
    }
}
```

---

## ⚠️ Security Best Practices

### Jenkins Specific

1. **Use credentials() binding** instead of withCredentials() blocks
2. **Define credentials in environment block** for better visibility
3. **Never log credentials** in console output
4. **Use credential masking** (automatic with credentials() function)
5. **Separate staging and production credentials**
6. **Use different AWS IAM users** for each environment
7. **Enable Jenkins security** with proper authentication
8. **Restrict credential access** using credential domains
9. **Enable audit logging** for credential usage
10. **Use credential folders** for better organization (optional)

### AWS IAM Best Practices

1. **Use separate IAM users** for staging and production
2. **Enable MFA** for IAM users with console access (if applicable)
3. **Regularly rotate access keys** (every 90 days)
4. **Use IAM roles** where possible instead of access keys
5. **Implement least privilege** - only grant necessary permissions
6. **Enable CloudTrail** for audit logging
7. **Use Service Control Policies** (SCPs) for additional guardrails
8. **Tag IAM users** with environment and purpose
9. **Monitor access key usage** with IAM Access Advisor
10. **Set up AWS Config rules** for compliance monitoring

### General Security

1. **Never commit credentials** to version control
2. **Use .gitignore** for sensitive files
3. **Enable Jenkins' built-in encryption** for credential storage
4. **Regularly backup Jenkins credentials**
5. **Implement IP whitelisting** for Jenkins access
6. **Use HTTPS** for Jenkins web interface
7. **Enable CSRF protection** in Jenkins
8. **Regular security audits** of credentials
9. **Incident response plan** for credential compromise
10. **Security training** for team members

---

## 🔄 Secret Rotation

### Password Requirements

| Secret | Minimum Length | Requirements |
|--------|---------------|--------------|
| AWS Secret Access Key | N/A | Generated by AWS |
| Database Password | 16 characters | Uppercase, lowercase, numbers, special chars |
| Splunk Password | 12 characters | Uppercase, lowercase, numbers |
| App Secret Key | 32 characters | Random alphanumeric |
| Splunk HEC Token | N/A | UUID format |
| Jira API Token | N/A | Generated by Atlassian |

### Rotation Schedule

| Secret | Rotation Frequency | Impact | Downtime Required |
|--------|-------------------|--------|-------------------|
| AWS Access Keys | Every 90 days | Update Jenkins credentials | No |
| Database Password | Every 90 days | Update credentials + trigger deployment | Yes (brief) |
| Splunk Password | Every 90 days | Update credentials + trigger deployment | Yes (brief) |
| App Secret Key | As needed | Update credentials + trigger deployment | Yes |
| Splunk HEC Token | Every 180 days | Update credentials + trigger deployment | No |
| Jira API Token | Every 180 days | Update Jenkins credentials | No |
| Discord Webhooks | Only if compromised | Update Jenkins credentials | No |

### Rotating AWS Credentials

#### Staging

```bash
# 1. Create new access key
aws iam create-access-key --user-name jenkins-cd-staging

# 2. Update Jenkins credential
# Go to: Manage Jenkins → Manage Credentials → aws-infrastructure-credentials
# Update the username and password with new keys

# 3. Test by running the pipeline

# 4. Deactivate old key
aws iam update-access-key \
  --user-name jenkins-cd-staging \
  --access-key-id OLD_ACCESS_KEY_ID \
  --status Inactive

# 5. Wait 24-48 hours, then delete old key
aws iam delete-access-key \
  --user-name jenkins-cd-staging \
  --access-key-id OLD_ACCESS_KEY_ID
```

#### Production

```bash
# 1. Create new access key
aws iam create-access-key --user-name jenkins-cd-production

# 2. Update Jenkins credential
# Go to: Manage Jenkins → Manage Credentials → aws-infrastructure-credentials-prod
# Update the username and password with new keys

# 3. Test by running the pipeline

# 4. Deactivate old key
aws iam update-access-key \
  --user-name jenkins-cd-production \
  --access-key-id OLD_ACCESS_KEY_ID \
  --status Inactive

# 5. Wait 24-48 hours, then delete old key
aws iam delete-access-key \
  --user-name jenkins-cd-production \
  --access-key-id OLD_ACCESS_KEY_ID
```

### Rotating Database Passwords

```bash
# 1. Generate new password
NEW_PASSWORD=$(openssl rand -base64 24)

# 2. Update Jenkins credential
# Go to: Manage Jenkins → Manage Credentials
# Update db-password-staging or db-password-production

# 3. Trigger pipeline deployment
# The new password will be applied to RDS during the next apply

# 4. Verify application connectivity after deployment
```

### Rotating Jira API Token

```bash
# 1. Create new API token
# Go to: https://id.atlassian.com/manage-profile/security/api-tokens
# Create new token labeled "Jenkins CD Pipeline - 2025-03"

# 2. Update Jenkins credential
# Go to: Manage Jenkins → Manage Credentials → jira-credentials
# Update the password field with the new token

# 3. Test by triggering a failure scenario (optional)

# 4. Revoke old API token
# Go back to Atlassian and delete the old token
```

### Rotating Discord Webhooks

```bash
# 1. Create new webhook in Discord
# Server Settings → Integrations → Webhooks → Create Webhook

# 2. Update Jenkins credential
# Go to: Manage Jenkins → Manage Credentials
# Update discord-webhook-staging or discord-webhook-production

# 3. Test by running pipeline

# 4. Delete old webhook in Discord
# Server Settings → Integrations → Webhooks → Delete
```

---

## 🆘 Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "Access Denied" in Terraform | Missing IAM permissions | Check IAM policy includes required actions |
| "Invalid credentials" error | Incorrect credential ID | Verify credential ID matches Jenkinsfile exactly |
| "Credential not found" | Credential deleted or renamed | Check credential exists in Jenkins |
| State locking errors | Missing DynamoDB permissions | Add DynamoDB actions to IAM policy |
| "Discord notification failed" | Invalid webhook URL | Verify webhook exists in Discord and URL is correct |
| "Jira ticket creation failed" | Invalid API token or permissions | Verify API token and user has "Create Issues" permission |
| Environment variables not set | Credential binding issue | Check credentials() function syntax in Jenkinsfile |
| Pipeline hangs on input | Approval timeout | Click "Approve" or increase timeout in Jenkinsfile |

### Verifying Credentials

#### Test AWS Credentials

```bash
# Set credentials locally
export AWS_ACCESS_KEY_ID="your-staging-key"
export AWS_SECRET_ACCESS_KEY="your-staging-secret"

# Test authentication
aws sts get-caller-identity

# Test S3 state bucket access
aws s3 ls s3://gogs-app-terraform-state-YOUR_ACCOUNT_ID/

# Test DynamoDB lock table
aws dynamodb describe-table --table-name gogs-app-terraform-locks

# Test EC2 permissions
aws ec2 describe-vpcs --region us-east-1
```

#### Test Jira API

```bash
# Test authentication
curl -u "your.email@company.com:your-api-token" \
  https://your-company.atlassian.net/rest/api/2/myself

# Test project access
curl -u "your.email@company.com:your-api-token" \
  https://your-company.atlassian.net/rest/api/2/project/INFRA

# Test issue creation permissions
curl -u "your.email@company.com:your-api-token" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"fields":{"project":{"key":"INFRA"},"summary":"Test","issuetype":{"name":"Bug"}}}' \
  https://your-company.atlassian.net/rest/api/2/issue
```

#### Test Discord Webhook

```bash
# Send test message
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"content":"Test message from Jenkins"}' \
  "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL"
```

### Debugging Jenkins Pipeline

1. **Enable debug logging:**
   ```groovy
   pipeline {
       agent any
       options {
           timestamps()
           // Add this for more verbose output
           buildDiscarder(logRotator(numToKeepStr: '10'))
       }
   }
   ```

2. **Check credential bindings:**
   ```groovy
   steps {
       script {
           echo "AWS_ACCESS_KEY_ID is set: ${env.AWS_ACCESS_KEY_ID != null}"
           echo "TF_VAR_db_username is set: ${env.TF_VAR_db_username != null}"
           // Never echo actual values!
       }
   }
   ```

3. **Test credential access:**
   ```groovy
   steps {
       sh '''
           echo "Testing AWS credentials..."
           aws sts get-caller-identity
       '''
   }
   ```

### Jenkins Credential Backup

```bash
# Backup Jenkins credentials (requires access to Jenkins server)
cd /var/lib/jenkins
sudo tar -czf jenkins-credentials-backup-$(date +%Y%m%d).tar.gz credentials.xml

# Restore credentials
sudo tar -xzf jenkins-credentials-backup-YYYYMMDD.tar.gz
sudo systemctl restart jenkins
```

---

## 📊 CD Pipeline Flow

```mermaid
graph TD
    A[Pipeline Triggered] --> B[Checkout Code]
    B --> C[Setup Tools]
    C --> D[Staging: Init]
    D --> E[Staging: Plan]
    E --> F{Changes Detected?}
    F -->|Yes| G[Staging: Apply]
    F -->|No| H[Staging: Skip Apply]
    G --> I[Production: Init]
    H --> I
    I --> J[Production: Plan]
    J --> K{Changes Detected?}
    K -->|Yes| L[Production: Approval Required]
    K -->|No| M[Production: Skip Apply]
    L -->|Approved| N[Production: Apply]
    N --> O[Summary]
    M --> O
    O --> P[Cleanup Workspace]
    
    G --> Q[Send Discord Success Notification]
    N --> R[Send Discord Success Notification]
    
    S[Failure] --> T[Send Discord Failure Notification]
    T --> U[Create Jira Ticket]
```

---

## 📚 References

- [Jenkins Credentials Plugin](https://plugins.jenkins.io/credentials/)
- [Jenkins Credentials Binding Plugin](https://plugins.jenkins.io/credentials-binding/)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform AWS Provider Authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)
- [Discord Webhooks Documentation](https://discord.com/developers/docs/resources/webhook)
- [Jira REST API Documentation](https://developer.atlassian.com/cloud/jira/platform/rest/v2/)

---

## 📞 Support

- **Jenkins Issues**: Check build logs and Jenkins system log
- **AWS IAM Issues**: Review IAM policy and use policy simulator
- **Discord Issues**: Verify webhook URL and channel permissions
- **Jira Issues**: Check API token and user permissions
- **Terraform Issues**: Verify Terraform and Terragrunt versions

**Related Documentation:**
- [GH-CREDENTIALS.md](GH-CREDENTIALS.md) - CI pipeline credentials
- [README.md](README.md) - Project overview
- [MODULES.md](MODULES.md) - Terraform modules documentation
- [Jenkinsfile](Jenkinsfile) - Main CD pipeline definition
