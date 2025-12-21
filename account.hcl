#------------------------------------------------------------------------------
# Account-level Configuration
# Contains settings that apply to the entire AWS account
#------------------------------------------------------------------------------

locals {
  # AWS Account ID - should be set via environment variable for security
  # Set: export TF_VAR_aws_account_id="123456789012"
  aws_account_id = get_env("TF_VAR_aws_account_id", "CHANGE_ME")
  
  # Project name used for resource naming and tagging
  project_name = "gogs-fork"
  
  # Terraform Cloud Organization (if using Terraform Cloud)
  # Set: export TF_CLOUD_ORGANIZATION="your-org-name"
  terraform_cloud_organization = get_env("TF_CLOUD_ORGANIZATION", "")
}
