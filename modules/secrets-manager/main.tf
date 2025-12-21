terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#------------------------------------------------------------------------------
# AWS Secrets Manager Module
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Database Credentials Secret
#------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "database" {
  name                    = "${var.project_name}/${var.environment}/database"
  description             = "Database credentials for ${var.project_name} ${var.environment}"
  recovery_window_in_days = var.recovery_window_in_days
  kms_key_id              = var.create_kms_key ? aws_kms_key.secrets[0].id : var.kms_key_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-database-secret"
  })
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = var.db_port
    database = var.db_name
  })
}

#------------------------------------------------------------------------------
# Application Secrets
#------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "application" {
  name                    = "${var.project_name}/${var.environment}/application"
  description             = "Application secrets for ${var.project_name} ${var.environment}"
  recovery_window_in_days = var.recovery_window_in_days
  kms_key_id              = var.create_kms_key ? aws_kms_key.secrets[0].id : var.kms_key_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-application-secret"
  })
}

resource "aws_secretsmanager_secret_version" "application" {
  secret_id     = aws_secretsmanager_secret.application.id
  secret_string = jsonencode(var.application_secrets)
}

#------------------------------------------------------------------------------
# Splunk Credentials Secret
#------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "splunk" {
  count                   = var.create_splunk_secret ? 1 : 0
  name                    = "${var.project_name}/${var.environment}/splunk"
  description             = "Splunk credentials for ${var.project_name} ${var.environment}"
  recovery_window_in_days = var.recovery_window_in_days
  kms_key_id              = var.create_kms_key ? aws_kms_key.secrets[0].id : var.kms_key_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-splunk-secret"
  })
}

resource "aws_secretsmanager_secret_version" "splunk" {
  count     = var.create_splunk_secret ? 1 : 0
  secret_id = aws_secretsmanager_secret.splunk[0].id
  secret_string = jsonencode({
    admin_password = var.splunk_admin_password
    hec_token      = var.splunk_hec_token
  })
}

#------------------------------------------------------------------------------
# DockerHub Credentials Secret (for pulling images)
#------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "dockerhub" {
  count                   = var.create_dockerhub_secret ? 1 : 0
  name                    = "${var.project_name}/${var.environment}/dockerhub"
  description             = "DockerHub credentials for ${var.project_name} ${var.environment}"
  recovery_window_in_days = var.recovery_window_in_days
  kms_key_id              = var.create_kms_key ? aws_kms_key.secrets[0].id : var.kms_key_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-dockerhub-secret"
  })
}

resource "aws_secretsmanager_secret_version" "dockerhub" {
  count     = var.create_dockerhub_secret ? 1 : 0
  secret_id = aws_secretsmanager_secret.dockerhub[0].id
  secret_string = jsonencode({
    username = var.dockerhub_username
    password = var.dockerhub_password
  })
}

#------------------------------------------------------------------------------
# Custom Secrets
#------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "custom" {
  for_each = var.custom_secrets

  name                    = "${var.project_name}/${var.environment}/${each.key}"
  description             = each.value.description
  recovery_window_in_days = var.recovery_window_in_days
  kms_key_id              = var.create_kms_key ? aws_kms_key.secrets[0].id : var.kms_key_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-${each.key}-secret"
  })
}

resource "aws_secretsmanager_secret_version" "custom" {
  for_each = var.custom_secrets

  secret_id     = aws_secretsmanager_secret.custom[each.key].id
  secret_string = jsonencode(each.value.value)
}

#------------------------------------------------------------------------------
# KMS Key for Secrets Encryption (optional)
#------------------------------------------------------------------------------

resource "aws_kms_key" "secrets" {
  count                   = var.create_kms_key ? 1 : 0
  description             = "KMS key for ${var.project_name} ${var.environment} secrets"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow ECS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-secrets-kms"
  })
}

resource "aws_kms_alias" "secrets" {
  count         = var.create_kms_key ? 1 : 0
  name          = "alias/${var.project_name}-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets[0].key_id
}

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
