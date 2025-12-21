#------------------------------------------------------------------------------
# Secrets Manager Module Outputs
#------------------------------------------------------------------------------

output "database_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.database.arn
}

output "database_secret_name" {
  description = "Name of the database credentials secret"
  value       = aws_secretsmanager_secret.database.name
}

output "application_secret_arn" {
  description = "ARN of the application secrets"
  value       = aws_secretsmanager_secret.application.arn
}

output "application_secret_name" {
  description = "Name of the application secrets"
  value       = aws_secretsmanager_secret.application.name
}

output "splunk_secret_arn" {
  description = "ARN of the Splunk credentials secret"
  value       = var.create_splunk_secret ? aws_secretsmanager_secret.splunk[0].arn : null
}

output "splunk_secret_name" {
  description = "Name of the Splunk credentials secret"
  value       = var.create_splunk_secret ? aws_secretsmanager_secret.splunk[0].name : null
}

output "dockerhub_secret_arn" {
  description = "ARN of the DockerHub credentials secret"
  value       = var.create_dockerhub_secret ? aws_secretsmanager_secret.dockerhub[0].arn : null
}

output "dockerhub_secret_name" {
  description = "Name of the DockerHub credentials secret"
  value       = var.create_dockerhub_secret ? aws_secretsmanager_secret.dockerhub[0].name : null
}

output "custom_secret_arns" {
  description = "Map of custom secret ARNs"
  value       = { for k, v in aws_secretsmanager_secret.custom : k => v.arn }
}

output "custom_secret_names" {
  description = "Map of custom secret names"
  value       = { for k, v in aws_secretsmanager_secret.custom : k => v.name }
}

output "all_secret_arns" {
  description = "List of all secret ARNs for IAM policies"
  value = compact(concat(
    [aws_secretsmanager_secret.database.arn],
    [aws_secretsmanager_secret.application.arn],
    var.create_splunk_secret ? [aws_secretsmanager_secret.splunk[0].arn] : [],
    var.create_dockerhub_secret ? [aws_secretsmanager_secret.dockerhub[0].arn] : [],
    [for s in aws_secretsmanager_secret.custom : s.arn]
  ))
}

output "kms_key_arn" {
  description = "ARN of the KMS key for secrets encryption"
  value       = var.create_kms_key ? aws_kms_key.secrets[0].arn : null
}

output "kms_key_id" {
  description = "ID of the KMS key for secrets encryption"
  value       = var.create_kms_key ? aws_kms_key.secrets[0].key_id : null
}
