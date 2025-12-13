#------------------------------------------------------------------------------
# VPC Module - Production Environment
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
  # Larger CIDR for production
  vpc_cidr = "10.1.0.0/16"
  
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]
  
  availability_zones = local.region_vars.locals.availability_zones
  
  enable_nat_gateway = true
}
