#------------------------------------------------------------------------------
# Terragrunt Root Configuration
# This file contains common configurations shared across all environments
#------------------------------------------------------------------------------

# Configure Terragrunt to store state in Terraform Cloud
# The remote_state block will generate a backend.tf file with the proper configuration
remote_state {
  backend = "remote"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    # Terraform Cloud organization name (set via environment variable)
    organization = local.terraform_cloud_organization
    
    # Workspace naming pattern: <project>-<environment>-<region>-<module>
    # Example: gogs-fork-production-us-east-1-vpc
    workspaces = {
      name = "${local.project_name}-${local.environment}-${local.aws_region}-${basename(get_terragrunt_dir())}"
    }
  }
}

# Generate provider configuration
# Note: Modules already have terraform{} and required_providers blocks
# This only generates the provider configuration with region and tags
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      Project     = "${local.project_name}"
      Environment = "${local.environment}"
      ManagedBy   = "Terraform"
      Repository  = "gogs-fork-infrastructure-aws"
    }
  }
}
EOF
}

# Define local variables
locals {
  # Load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  
  # Load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  
  # Load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract commonly used variables
  aws_account_id               = local.account_vars.locals.aws_account_id
  aws_region                   = local.region_vars.locals.aws_region
  environment                  = local.environment_vars.locals.environment
  project_name                 = local.account_vars.locals.project_name
  terraform_cloud_organization = local.account_vars.locals.terraform_cloud_organization
}

# Inputs to pass to all modules
inputs = {
  project_name = local.project_name
  environment  = local.environment
  aws_region   = local.aws_region
  
  tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "Terraform"
  }
}
