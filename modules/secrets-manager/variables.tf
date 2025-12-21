#------------------------------------------------------------------------------
# Secrets Manager Module Variables
#------------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (if not creating a new one)"
  type        = string
  default     = null
}

variable "create_kms_key" {
  description = "Create a new KMS key for secrets encryption"
  type        = bool
  default     = true
}

variable "recovery_window_in_days" {
  description = "Number of days before secret is permanently deleted"
  type        = number
  default     = 30
}

#------------------------------------------------------------------------------
# Database Credentials
#------------------------------------------------------------------------------

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_host" {
  description = "Database host"
  type        = string
  default     = ""
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Application Secrets
#------------------------------------------------------------------------------

variable "application_secrets" {
  description = "Map of application secrets"
  type        = map(string)
  default     = {}
  sensitive   = true
}

#------------------------------------------------------------------------------
# Splunk Credentials
#------------------------------------------------------------------------------

variable "create_splunk_secret" {
  description = "Create Splunk credentials secret"
  type        = bool
  default     = true
}

variable "splunk_admin_password" {
  description = "Splunk admin password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "splunk_hec_token" {
  description = "Splunk HTTP Event Collector token"
  type        = string
  sensitive   = true
  default     = ""
}

#------------------------------------------------------------------------------
# DockerHub Credentials
#------------------------------------------------------------------------------

variable "create_dockerhub_secret" {
  description = "Create DockerHub credentials secret"
  type        = bool
  default     = false
}

variable "dockerhub_username" {
  description = "DockerHub username"
  type        = string
  sensitive   = true
  default     = ""
}

variable "dockerhub_password" {
  description = "DockerHub password or access token"
  type        = string
  sensitive   = true
  default     = ""
}

#------------------------------------------------------------------------------
# Custom Secrets
#------------------------------------------------------------------------------

variable "custom_secrets" {
  description = "Map of custom secrets to create"
  type = map(object({
    description = string
    value       = map(string)
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
