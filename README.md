# Gogs Infrastructure AWS

Infrastructure as Code (IaC) repository for deploying and managing AWS infrastructure using Terraform and Terragrunt. This repository provisions the complete infrastructure stack for the Gogs application, including ECS containers, RDS database, monitoring server infrastructure, and secure secrets management.

> **⚠️ Important**: This repository handles **infrastructure provisioning only**. Application configuration and software installation (including Splunk) should be managed by Ansible or other configuration management tools.

## 🏗️ Architecture Overview

### Separation of Concerns

This repository follows infrastructure-as-code best practices by **only provisioning infrastructure**:

**Terraform/Terragrunt (This Repository):**
- ✅ Creates AWS resources (VPC, EC2, RDS, ECS, etc.)
- ✅ Configures networking and security groups
- ✅ Manages IAM roles and policies
- ✅ Provisions storage (EBS volumes, S3)

**Ansible/Configuration Management (Separate Repository):**
- ✅ Installs and configures Splunk
- ✅ Manages application configurations
- ✅ Handles software updates and patches
- ✅ Configures monitoring and alerting
- ✅ Manages users and access control

### Infrastructure Diagram

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud                                       │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                            VPC                                         │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │  │
│  │  │                    Public Subnets                                │  │  │
│  │  │  ┌─────────────────┐    ┌─────────────────┐                     │  │  │
│  │  │  │      ALB        │    │  EC2 Instance   │                     │  │  │
│  │  │  │ (Load Balancer) │    │  (for Splunk)   │                     │  │  │
│  │  │  └────────┬────────┘    └─────────────────┘                     │  │  │
│  │  └───────────┼─────────────────────────────────────────────────────┘  │  │
│  │              │                                                         │  │
│  │  ┌───────────▼─────────────────────────────────────────────────────┐  │  │
│  │  │                   Private Subnets                                │  │  │
│  │  │  ┌─────────────────┐    ┌─────────────────┐                     │  │  │
│  │  │  │  ECS Fargate    │    │      RDS        │                     │  │  │
│  │  │  │  (Docker App)   │◄──►│  (PostgreSQL)   │                     │  │  │
│  │  │  └─────────────────┘    └─────────────────┘                     │  │  │
│  │  └─────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌─────────────────┐                                                        │
│  │ Secrets Manager │ (Stores DB credentials, API keys, Splunk tokens)       │
│  └─────────────────┘                                                        │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 📁 Repository Structure

```text
gogs-fork-infrastructure-aws/
├── 📄 terragrunt.hcl                    # Root Terragrunt configuration
├── 📄 account.hcl                       # AWS account-level settings
├── 📄 Jenkinsfile                       # Main CD pipeline (dispatcher)
├── 📄 README.md                         # This file
├── 📄 GH-CREDENTIALS.md                 # GitHub Actions CI credentials documentation
├── 📄 JENKINS-CREDENTIALS.md            # Jenkins CD credentials documentation
├── 📄 MODULES.md                        # Terraform modules documentation
│
├── 📂 .github/
│   └── 📂 workflows/
│       └── 📄 ci.yml                    # GitHub Actions CI workflow
│
├── 📂 jenkins/                          # Jenkins pipeline configurations
│   └── 📂 shared/
│       └── 📄 pipeline-helpers.groovy   # Shared functions (Discord, Jira)
│
├── 📂 modules/                          # Reusable Terraform modules
│   ├── 📂 vpc/                          # Network infrastructure
│   │   ├── 📄 main.tf
│   │   ├── 📄 variables.tf
│   │   └── 📄 outputs.tf
│   │
│   ├── 📂 ecs/                          # Container service (Docker from DockerHub)
│   │   ├── 📄 main.tf
│   │   ├── 📄 variables.tf
│   │   └── 📄 outputs.tf
│   │
│   ├── 📂 rds/                          # PostgreSQL database
│   │   ├── 📄 main.tf
│   │   ├── 📄 variables.tf
│   │   └── 📄 outputs.tf
│   │
│   ├── 📂 ec2-splunk/                   # Splunk server infrastructure (Ansible installs Splunk)
│   │   ├── 📄 main.tf
│   │   ├── 📄 variables.tf
│   │   └── 📄 outputs.tf
│   │
│   └── 📂 secrets-manager/              # AWS Secrets Manager
│       ├── 📄 main.tf
│       ├── 📄 variables.tf
│       └── 📄 outputs.tf
│
└── 📂 environments/                     # Environment-specific configurations
    └── 📂 us-east-1/                    # AWS Region
        ├── 📄 region.hcl                # Region-level settings
        │
        ├── 📂 staging/                  # Staging environment
        │   ├── 📄 env.hcl               # Environment settings
        │   ├── 📂 vpc/
        │   │   └── 📄 terragrunt.hcl
        │   ├── 📂 ecs/
        │   │   └── 📄 terragrunt.hcl
        │   ├── 📂 rds/
        │   │   └── 📄 terragrunt.hcl
        │   ├── 📂 ec2-splunk/
        │   │   └── 📄 terragrunt.hcl
        │   └── 📂 secrets-manager/
        │       └── 📄 terragrunt.hcl
        │
        └── 📂 production/               # Production environment
            ├── 📄 env.hcl               # Environment settings
            ├── 📂 vpc/
            │   └── 📄 terragrunt.hcl
            ├── 📂 ecs/
            │   └── 📄 terragrunt.hcl
            ├── 📂 rds/
            │   └── 📄 terragrunt.hcl
            ├── 📂 ec2-splunk/
            │   └── 📄 terragrunt.hcl
            └── 📂 secrets-manager/
                └── 📄 terragrunt.hcl
│
├── 📂 test/                             # Terraform module unit tests
│   ├── 📄 go.mod                        # Go module definition
│   ├── 📄 README.md                     # Test documentation
│   ├── 📄 vpc_test.go                   # VPC module tests
│   ├── 📄 ecs_test.go                   # ECS module tests
│   ├── 📄 rds_test.go                   # RDS module tests
│   ├── 📄 ec2_splunk_test.go            # EC2-Splunk module tests
│   └── 📄 secrets_manager_test.go       # Secrets Manager module tests
```

## 📋 File Descriptions

### Root Configuration Files

| File | Purpose | Importance |
| ---- | ------- | ---------- |
| `terragrunt.hcl` | Root Terragrunt config with remote state, provider generation, and common inputs | **Critical** - Defines Terraform Cloud backend, AWS provider, and common tags |
| `account.hcl` | AWS account ID, project name, and Terraform Cloud organization | **Critical** - Must be configured with your AWS account ID and TF Cloud org |
| `TERRAFORM-CLOUD-SETUP.md` | Terraform Cloud authentication and setup guide | **Critical** - State management configuration |
| `Jenkinsfile` | Main CD pipeline dispatcher | **Critical** - Routes to environment-specific pipelines |
| `README.md` | Repository documentation | Documentation |
| `GH-CREDENTIALS.md` | GitHub Actions CI credentials documentation | **Important** - CI security reference |
| `JENKINS-CREDENTIALS.md` | Jenkins CD credentials documentation | **Important** - CD security reference |
| `MODULES.md` | Terraform modules documentation | **Important** - Module reference and usage |

### Jenkins Pipelines

| File | Purpose |
| ---- | ------- |
| `Jenkinsfile` | Main pipeline that automatically plans and applies both staging and production environments |
| `jenkins/shared/pipeline-helpers.groovy` | Shared functions for Discord notifications and Jira ticket creation |

### Unit Tests

| File | Purpose |
| ---- | ------- |
| `test/vpc_test.go` | VPC module unit tests (CIDR validation, NAT Gateway, tagging) |
| `test/ecs_test.go` | ECS module unit tests (container config, auto-scaling, Docker images) |
| `test/rds_test.go` | RDS module unit tests (DB engines, instance classes, storage) |
| `test/ec2_splunk_test.go` | EC2-Splunk module unit tests (instance types, volumes, network) |
| `test/secrets_manager_test.go` | Secrets Manager unit tests (secret types, KMS, recovery window) |

### GitHub Actions

| File | Purpose |
| ---- | ------- |
| `.github/workflows/ci.yml` | CI pipeline: `terraform fmt`, `validate`, `tflint`, `checkov`, `terragrunt validate` |

### Terraform Modules

| Module | Purpose | Resources Created |
| ------ | ------- | ----------------- |
| `vpc` | Network infrastructure | VPC, Subnets (public/private), Internet Gateway, NAT Gateway, Route Tables |
| `ecs` | Container service | ECS Cluster, Task Definition, Service, ALB, Target Group, Security Groups, IAM Roles, Auto Scaling |
| `rds` | Database service | RDS Instance (PostgreSQL), Subnet Group, Parameter Group, Security Group, Enhanced Monitoring |
| `ec2-splunk` | **Monitoring server infrastructure** (Splunk installation via Ansible) | EC2 Instance, Security Group, IAM Role/Profile, EBS Volume, Optional Elastic IP |
| `secrets-manager` | Secrets storage | Secrets (DB, App, Splunk, DockerHub), KMS Key for encryption |

### Environment Configurations

| File | Purpose |
| ---- | ------- |
| `region.hcl` | AWS region and availability zones |
| `env.hcl` | Environment name (staging/production) |
| `*/terragrunt.hcl` | Module-specific inputs and dependencies |

## 🔄 CI/CD Pipeline

### GitHub Actions (CI)

The CI pipeline runs on every push and pull request to validate the infrastructure code:

```text
Push/PR → Format Check → Validate → TFLint → Checkov → Terragrunt Validate → Plan (PRs)
```

**Jobs:**
1. **terraform-fmt** - Checks Terraform formatting
2. **terraform-validate** - Validates module syntax
3. **tflint** - Lints Terraform code
4. **checkov** - Security scanning
5. **terragrunt-validate-staging** - Validates staging configuration
6. **terragrunt-validate-production** - Validates production configuration
7. **terragrunt-plan-staging** - Creates plan for PRs
8. **docs-check** - Validates documentation exists

### Jenkins (CD)

The CD pipeline handles actual infrastructure deployment with **Discord notifications** and **Jira ticket creation on failure**:

```text
Manual Trigger → Discord Notify → Validate → Init → Plan → Approval → Apply → Discord Notify
                                                              ↓ (on failure)
                                                        Create Jira Ticket
```

**Pipeline Structure:**
- `Jenkinsfile` - Main pipeline that handles both environments automatically
- `jenkins/shared/pipeline-helpers.groovy` - Shared notification functions

**Pipeline Behavior:**
- Runs `terragrunt plan` for staging, applies only if changes detected
- Runs `terragrunt plan` for production, applies only if changes detected
- Production changes require manual approval before apply
- Discord notifications sent at each stage
- Jira ticket created automatically on failure

**Notifications:**
- **Discord**: Real-time notifications for pipeline start, approval requests, success, and failure
- **Jira**: Automatic ticket creation on pipeline failure with error details

## 🚀 Getting Started

### Prerequisites

- Terraform >= 1.5.0
- Terragrunt >= 0.53.0
- AWS CLI configured with appropriate credentials
- **Terraform Cloud account** - Sign up at [https://app.terraform.io](https://app.terraform.io)
- Jenkins (for CD) with Discord Notifier and Jira plugins
- GitHub repository (for CI)
- Discord webhook URL for notifications
- Jira account with API access

### Initial Setup

1. **Configure Terraform Cloud authentication:**
   ```bash
   # See detailed instructions in TERRAFORM-CLOUD-SETUP.md
   
   # Option 1: Using terraform login (interactive)
   terraform login
   
   # Option 2: Set environment variable
   export TF_TOKEN_app_terraform_io="your_terraform_cloud_api_token"
   ```

2. **Set required environment variables:**
   ```bash
   # Terraform Cloud organization
   export TF_CLOUD_ORGANIZATION="your-org-name"

   # AWS account ID (prevents hardcoding)
   export TF_VAR_aws_account_id="123456789012"

   # Application secrets (see TERRAFORM-CLOUD-SETUP.md for full list)
   export TF_VAR_db_username="your_db_admin"
   export TF_VAR_db_password="your_secure_password"
   export TF_VAR_app_secret_key="your_app_secret_key"
   export TF_VAR_splunk_hec_token="your_hec_token"  # Stored in Secrets Manager for Ansible
   ```

   **📖 For complete setup instructions, see [TERRAFORM-CLOUD-SETUP.md](TERRAFORM-CLOUD-SETUP.md)**

3. **Set up required secrets in your CI/CD systems**
   - For GitHub Actions (CI): See [GH-CREDENTIALS.md](GH-CREDENTIALS.md)
   - For Jenkins (CD): See [JENKINS-CREDENTIALS.md](JENKINS-CREDENTIALS.md)
   - For Terraform Cloud: See [TERRAFORM-CLOUD-SETUP.md](TERRAFORM-CLOUD-SETUP.md)

### Deploying Infrastructure

#### Using Terragrunt directly (local development):

```bash
# Navigate to environment
cd environments/us-east-1/staging

# Export required environment variables
export TF_VAR_db_username="your_username"
export TF_VAR_db_password="your_password"
# ... (see JENKINS-CREDENTIALS.md for all required variables)

# Plan all modules
terragrunt run-all plan

# Apply all modules
terragrunt run-all apply

# Apply specific module
cd vpc
terragrunt apply
```

### Post-Deployment - Ansible Configuration

After infrastructure is provisioned, use your Ansible repository to configure software:

```bash
# 1. Export infrastructure outputs for Ansible inventory
cd environments/us-east-1/staging

# Get Splunk server IP
export SPLUNK_IP=$(terragrunt output -raw splunk_public_ip --terragrunt-working-dir=ec2-splunk)

# Get RDS endpoint
export DB_ENDPOINT=$(terragrunt output -raw db_instance_endpoint --terragrunt-working-dir=rds)

# 2. Update Ansible inventory with infrastructure details
echo "[splunk]" > inventory/staging
echo "splunk-server ansible_host=${SPLUNK_IP} ansible_user=ec2-user" >> inventory/staging

# 3. Run Ansible playbooks (in your Ansible repository)
ansible-playbook -i inventory/staging playbooks/splunk-install.yml
ansible-playbook -i inventory/staging playbooks/splunk-configure.yml
```

**Key Outputs for Ansible:**
- `splunk_public_ip` / `splunk_private_ip` - Server access
- `data_volume_id` - EBS volume for /opt/splunk
- `instance_id` - For AWS Systems Manager
- `iam_role_arn` - IAM permissions (Secrets Manager access)
- `security_group_id` - Network configuration reference

#### Using Jenkins (recommended for production):

1. Navigate to Jenkins job
2. Select environment (staging/production)
3. Select action (plan/apply)
4. Review plan output
5. Approve and deploy

## 🔐 Security Considerations

1. **Never commit secrets** - All sensitive values are passed via environment variables or Terraform Cloud workspace variables
2. **Use AWS Secrets Manager** - Application credentials are stored encrypted and can be rotated
3. **Enable encryption** - RDS and EBS volumes are encrypted at rest with KMS
4. **Restrict network access** - Private subnets for databases, security groups limit access to only required sources
5. **IAM least privilege** - Roles have minimal required permissions for their specific tasks
6. **State file security** - Terraform Cloud provides encrypted remote state with access controls and audit logging
7. **Credential management** - No hardcoded credentials in code; all secrets use `get_env()` or are injected at runtime
8. **Terraform Cloud security** - Enable MFA, use team tokens for CI/CD, and regularly rotate API tokens

## 📊 Environment Differences

| Feature | Staging | Production |
| ------- | ------- | ---------- |
| RDS Instance | db.t3.micro | db.t3.medium |
| RDS Multi-AZ | ❌ | ✅ |
| ECS Task Size | 256 CPU / 512 MB | 512 CPU / 1024 MB |
| ECS Desired Count | 1 | 2 |
| Auto Scaling Max | 2 | 10 |
| Log Retention | 14 days | 90 days |
| Deletion Protection | ❌ | ✅ |
| Backup Retention | 7 days | 30 days |
| Splunk Instance | t3.medium | t3.large |
| Splunk Data Volume | 50 GB | 200 GB |

## 🛠️ Module Dependency Order

When deploying all modules, Terragrunt handles dependencies automatically:

```
1. VPC (no dependencies)
2. Secrets Manager (depends on RDS for DB host - circular dependency handled with mock outputs)
3. RDS (depends on VPC)
4. ECS (depends on VPC, RDS, Secrets Manager)
5. EC2 Splunk (depends on VPC, ECS, Secrets Manager)
```

## 📝 License

This project is licensed under the MIT License.

## 👥 Contributing

1. Create a feature branch from `main`
2. Make your changes
3. Ensure CI passes
4. Create a Pull Request
5. Wait for approval and merge

## 📞 Support

For issues or questions, please create a GitHub issue or contact the infrastructure team.