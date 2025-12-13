#------------------------------------------------------------------------------
# Secrets Manager Module - Staging Environment
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
  # Database credentials (values should come from environment variables or CI/CD secrets)
  db_username = get_env("TF_VAR_db_username", "admin")
  db_password = get_env("TF_VAR_db_password", "CHANGE_ME_IN_CI")
  db_host     = dependency.rds.outputs.db_instance_address
  db_port     = 5432
  db_name     = "gogsapp"
  
  # Application secrets
  application_secrets = {
    APP_SECRET_KEY = get_env("TF_VAR_app_secret_key", "CHANGE_ME_IN_CI")
  }
  
  # Splunk credentials
  create_splunk_secret  = true
  splunk_admin_password = get_env("TF_VAR_splunk_admin_password", "CHANGE_ME_IN_CI")
  splunk_hec_token      = get_env("TF_VAR_splunk_hec_token", "CHANGE_ME_IN_CI")
  
  # DockerHub credentials (optional)
  create_dockerhub_secret = false
  
  # Create KMS key for encryption
  create_kms_key = true
  
  recovery_window_in_days = 7  # Shorter for staging
}
