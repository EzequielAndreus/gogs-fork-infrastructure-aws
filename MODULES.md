# Terraform Modules Documentation

This document provides an overview of all Terraform modules in this repository, their purpose, key resources, and usage guidelines.

---

## 📋 Table of Contents

1. [VPC Module](#vpc-module)
2. [ECS Module](#ecs-module)
3. [RDS Module](#rds-module)
4. [EC2-Splunk Module](#ec2-splunk-module)
5. [Secrets Manager Module](#secrets-manager-module)

---

## VPC Module

**Path:** `modules/vpc/`

### Description

Creates the foundational network infrastructure for the AWS environment. This module provisions a Virtual Private Cloud (VPC) with public and private subnets across multiple availability zones, enabling secure and isolated network architecture.

### Key Resources

| Resource | Description |
|----------|-------------|
| `aws_vpc` | Main VPC with DNS support enabled |
| `aws_internet_gateway` | Internet Gateway for public subnet access |
| `aws_subnet` (public) | Public subnets with auto-assign public IP |
| `aws_subnet` (private) | Private subnets for internal resources |
| `aws_nat_gateway` | NAT Gateway for private subnet outbound access |
| `aws_eip` | Elastic IP for NAT Gateway |
| `aws_route_table` | Route tables for public and private subnets |

### Key Variables

| Variable | Type | Description |
|----------|------|-------------|
| `vpc_cidr` | string | CIDR block for the VPC (default: `10.0.0.0/16`) |
| `public_subnet_cidrs` | list(string) | CIDR blocks for public subnets |
| `private_subnet_cidrs` | list(string) | CIDR blocks for private subnets |
| `availability_zones` | list(string) | List of AZs to deploy subnets |
| `enable_nat_gateway` | bool | Enable NAT Gateway for private subnets |

### Outputs

- `vpc_id` - VPC identifier
- `public_subnet_ids` - List of public subnet IDs
- `private_subnet_ids` - List of private subnet IDs
- `nat_gateway_ip` - Public IP of the NAT Gateway

---

## ECS Module

**Path:** `modules/ecs/`

### Description

Deploys a containerized application using AWS Elastic Container Service (ECS) with Fargate launch type. This module creates an ECS cluster, task definitions, services, and an Application Load Balancer for Docker containers pulled from DockerHub.

### Key Resources

| Resource | Description |
|----------|-------------|
| `aws_ecs_cluster` | ECS cluster with Container Insights |
| `aws_ecs_task_definition` | Fargate task definition for containers |
| `aws_ecs_service` | ECS service with desired task count |
| `aws_lb` | Application Load Balancer |
| `aws_lb_target_group` | Target group for ECS tasks |
| `aws_lb_listener` | HTTP/HTTPS listeners |
| `aws_iam_role` | Task execution and task roles |
| `aws_security_group` | Security groups for ALB and ECS tasks |
| `aws_appautoscaling_target` | Auto-scaling configuration |
| `aws_cloudwatch_log_group` | Log group for container logs |

### Key Variables

| Variable | Type | Description |
|----------|------|-------------|
| `docker_image` | string | Docker image from DockerHub (e.g., `username/image:tag`) |
| `container_port` | number | Port exposed by the container (default: `8080`) |
| `task_cpu` | number | CPU units for the task (256-4096) |
| `task_memory` | number | Memory in MB for the task |
| `desired_count` | number | Number of task instances to run |
| `min_capacity` / `max_capacity` | number | Auto-scaling boundaries |
| `secrets_manager_arns` | list(string) | ARNs of secrets accessible by ECS |

### Outputs

- `cluster_id` - ECS cluster identifier
- `service_name` - ECS service name
- `alb_dns_name` - Application Load Balancer DNS name
- `alb_zone_id` - ALB hosted zone ID
- `task_security_group_id` - Security group ID for ECS tasks

---

## RDS Module

**Path:** `modules/rds/`

### Description

Provisions an Amazon RDS PostgreSQL database instance with configurable settings for high availability, security, and performance. Includes subnet groups, parameter groups, and security configurations for secure database access.

### Key Resources

| Resource | Description |
|----------|-------------|
| `aws_db_instance` | RDS PostgreSQL instance |
| `aws_db_subnet_group` | Subnet group for RDS |
| `aws_db_parameter_group` | Database parameter configuration |
| `aws_security_group` | Security group for database access |
| `aws_iam_role` | Enhanced monitoring role (optional) |

### Key Variables

| Variable | Type | Description |
|----------|------|-------------|
| `db_engine` | string | Database engine (default: `postgres`) |
| `db_engine_version` | string | Engine version (default: `15.4`) |
| `db_instance_class` | string | Instance class (default: `db.t3.micro`) |
| `db_allocated_storage` | number | Storage size in GB |
| `db_username` | string | Master username (sensitive) |
| `db_password` | string | Master password (sensitive) |
| `multi_az` | bool | Enable Multi-AZ deployment |
| `deletion_protection` | bool | Prevent accidental deletion |
| `allowed_security_groups` | list(string) | Security groups allowed to connect |

### Outputs

- `db_instance_endpoint` - Database connection endpoint
- `db_instance_port` - Database port
- `db_instance_id` - RDS instance identifier
- `db_security_group_id` - Security group ID for the database

---

## EC2-Splunk Module

**Path:** `modules/ec2-splunk/`

### Description

Deploys an EC2 instance configured for Splunk Enterprise monitoring. This module provisions the instance with necessary IAM roles for CloudWatch and Secrets Manager access, EBS volumes for data storage, and security configurations for Splunk web interface and HEC access.

### Key Resources

| Resource | Description |
|----------|-------------|
| `aws_instance` | EC2 instance with Splunk installation script |
| `aws_ebs_volume` | Additional EBS volume for Splunk data |
| `aws_volume_attachment` | Attaches data volume to instance |
| `aws_iam_role` | IAM role for CloudWatch and Secrets access |
| `aws_iam_instance_profile` | Instance profile for EC2 |
| `aws_security_group` | Security group for Splunk access |
| `aws_eip` | Elastic IP for consistent access |
| `aws_key_pair` | SSH key for instance access |

### Key Variables

| Variable | Type | Description |
|----------|------|-------------|
| `ami_id` | string | AMI ID (Amazon Linux 2 recommended) |
| `instance_type` | string | EC2 instance type (default: `t3.medium`) |
| `root_volume_size` | number | Root volume size in GB (default: `50`) |
| `data_volume_size` | number | Data volume size in GB (default: `100`) |
| `splunk_admin_password` | string | Splunk admin password (sensitive) |
| `splunk_hec_token` | string | HTTP Event Collector token (sensitive) |
| `allowed_cidr` | list(string) | CIDRs allowed to access Splunk web |
| `ssh_cidr` | list(string) | CIDRs allowed SSH access |

### Outputs

- `instance_id` - EC2 instance identifier
- `public_ip` - Public IP address
- `private_ip` - Private IP address
- `splunk_web_url` - Splunk web interface URL
- `splunk_hec_endpoint` - HTTP Event Collector endpoint

---

## Secrets Manager Module

**Path:** `modules/secrets-manager/`

### Description

Manages sensitive credentials and configuration using AWS Secrets Manager. Creates encrypted secrets for database credentials, application secrets, Splunk credentials, and DockerHub authentication with optional KMS encryption.

### Key Resources

| Resource | Description |
|----------|-------------|
| `aws_secretsmanager_secret` | Secret containers (database, app, Splunk, DockerHub) |
| `aws_secretsmanager_secret_version` | Secret values |
| `aws_kms_key` | KMS key for encryption (optional) |
| `aws_kms_alias` | KMS key alias |

### Secret Types

| Secret | Path | Description |
|--------|------|-------------|
| Database | `{project}/{env}/database` | DB username, password, host, port, database name |
| Application | `{project}/{env}/application` | Application-specific secrets |
| Splunk | `{project}/{env}/splunk` | Splunk admin password and HEC token |
| DockerHub | `{project}/{env}/dockerhub` | DockerHub username and password/token |

### Key Variables

| Variable | Type | Description |
|----------|------|-------------|
| `db_username` | string | Database username (sensitive) |
| `db_password` | string | Database password (sensitive) |
| `application_secrets` | map(string) | Application secrets key-value pairs |
| `splunk_admin_password` | string | Splunk admin password (sensitive) |
| `splunk_hec_token` | string | Splunk HEC token (sensitive) |
| `create_kms_key` | bool | Create dedicated KMS key (default: `true`) |
| `recovery_window_in_days` | number | Days before permanent deletion (default: `30`) |

### Outputs

- `database_secret_arn` - ARN of database credentials secret
- `application_secret_arn` - ARN of application secrets
- `splunk_secret_arn` - ARN of Splunk credentials secret
- `dockerhub_secret_arn` - ARN of DockerHub credentials secret
- `kms_key_arn` - ARN of KMS key (if created)

---

## Module Dependencies

```
┌─────────────────┐
│       VPC       │
└────────┬────────┘
         │
    ┌────┴────┬─────────────┐
    ▼         ▼             ▼
┌───────┐ ┌───────┐ ┌───────────────┐
│  ECS  │ │  RDS  │ │  EC2-Splunk   │
└───┬───┘ └───┬───┘ └───────┬───────┘
    │         │             │
    └─────────┴─────────────┘
              │
              ▼
    ┌─────────────────┐
    │ Secrets Manager │
    └─────────────────┘
```

### Dependency Flow

1. **VPC** - Must be created first (provides network foundation)
2. **Secrets Manager** - Can be created in parallel with VPC
3. **ECS, RDS, EC2-Splunk** - Require VPC outputs and Secrets Manager ARNs

---

## Testing

Unit tests for each module are located in the `test/` directory:

```
test/
├── vpc_test.go           # VPC module tests
├── ecs_test.go           # ECS module tests
├── rds_test.go           # RDS module tests
├── ec2_splunk_test.go    # EC2-Splunk module tests
├── secrets_manager_test.go # Secrets Manager module tests
└── go.mod                # Go module definition
```

Run tests with:

```bash
cd test
go test -v -timeout 30m
```

---

## Best Practices

1. **Use Terragrunt** - Leverage the environment configurations in `environments/` for DRY code
2. **Never hardcode secrets** - Always use Secrets Manager module
3. **Enable deletion protection** - For production RDS and critical resources
4. **Use Multi-AZ** - For production database deployments
5. **Tag all resources** - Use the `tags` variable consistently
6. **Review plans** - Always review `terragrunt plan` before applying
