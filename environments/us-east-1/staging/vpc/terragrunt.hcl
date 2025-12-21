#------------------------------------------------------------------------------
# VPC Module - Staging Environment
#------------------------------------------------------------------------------

# Include the root terragrunt.hcl configuration
include "root" {
  path = find_in_parent_folders()
}

# Use the VPC module
terraform {
  source = "../../../../modules//vpc"
}

# Load region-level variables
locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

# Module-specific inputs
inputs = {
  vpc_cidr = "10.0.0.0/16"
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  
  availability_zones = local.region_vars.locals.availability_zones
  
  enable_nat_gateway = true
}
