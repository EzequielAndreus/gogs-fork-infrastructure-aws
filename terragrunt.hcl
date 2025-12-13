#------------------------------------------------------------------------------
# Terragrunt Root Configuration
# This file contains common configurations shared across all environments
#------------------------------------------------------------------------------

# Configure Terragrunt to store state in S3
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "${local.project_name}-terraform-state-${local.aws_account_id}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "${local.project_name}-terraform-locks"
  }
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      Project     = "${local.project_name}"
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
  aws_account_id = local.account_vars.locals.aws_account_id
  aws_region     = local.region_vars.locals.aws_region
  environment    = local.environment_vars.locals.environment
  project_name   = local.account_vars.locals.project_name
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
