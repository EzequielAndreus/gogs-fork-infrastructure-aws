#------------------------------------------------------------------------------
# Secrets Manager Module - Production Environment
#------------------------------------------------------------------------------

# Include the root terragrunt.hcl configuration
include "root" {
  path = find_in_parent_folders()
}

# Use the Secrets Manager module
terraform {
  source = "../../../../modules//secrets-manager"
}

# Dependencies
dependency "rds" {
  config_path = "../rds"
  
  # Mock outputs for plan without apply
  mock_outputs = {
    db_instance_address = "mock-db.example.com"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Module-specific inputs
inputs = {
  # Database credentials - must be set via environment variables (no insecure defaults)
  db_username = get_env("TF_VAR_db_username", "validation_user")
  db_password = get_env("TF_VAR_db_password", "validation_pass_CHANGE_IN_PRODUCTION")
  db_host     = dependency.rds.outputs.db_instance_address
  db_port     = 5432
  db_name     = "gogsapp"
  
  # Application secrets - must be set via environment variables
  application_secrets = {
    APP_SECRET_KEY = get_env("TF_VAR_app_secret_key", "validation_secret_CHANGE_IN_PRODUCTION")
  }
  
  # Splunk credentials - must be set via environment variables
  create_splunk_secret  = true
  splunk_admin_password = get_env("TF_VAR_splunk_admin_password", "validation_splunk_admin_CHANGE_IN_PRODUCTION")
  splunk_hec_token      = get_env("TF_VAR_splunk_hec_token", "validation_hec_token_CHANGE_IN_PRODUCTION")
  
  # DockerHub credentials (optional)
  create_dockerhub_secret = false
  
  # Create KMS key for encryption
  create_kms_key = true
  
  # Longer recovery window for production
  recovery_window_in_days = 30
}
