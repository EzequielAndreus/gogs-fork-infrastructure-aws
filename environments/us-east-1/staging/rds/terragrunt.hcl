#------------------------------------------------------------------------------
# RDS Module - Staging Environment
#------------------------------------------------------------------------------

# Include the root terragrunt.hcl configuration
include "root" {
  path = find_in_parent_folders()
}

# Use the RDS module
terraform {
  source = "../../../../modules//rds"
}

# Dependencies
dependency "vpc" {
  config_path = "../vpc"
  
  # Mock outputs for plan without apply
  mock_outputs = {
    vpc_id             = "vpc-mock12345"
    private_subnet_ids = ["subnet-mock1", "subnet-mock2"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "ecs" {
  config_path = "../ecs"
  
  # Mock outputs for plan without apply
  mock_outputs = {
    ecs_security_group_id = "sg-mock12345"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  skip_outputs = true  # Break circular dependency - ECS depends on RDS outputs
}

# Module-specific inputs
inputs = {
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  
  # NOTE: Due to a circular dependency between RDS and ECS, allowed_security_groups is left empty here.
  # The ECS module will create a security group rule allowing ECS tasks to connect to RDS.
  # To allow ECS to connect to RDS:
  # 1. Deploy RDS first with empty allowed_security_groups
  # 2. Deploy ECS (which depends on RDS outputs)
  # 3. ECS module handles the security group rule creation
  # Alternatively: Use a separate Terragrunt configuration (e.g., rds-ecs-sg-rule) to add the ECS 
  # security group to the RDS security group after both resources are created.
  allowed_security_groups = []
  
  # Database configuration
  db_engine                 = "postgres"
  db_engine_version         = "15.4"
  db_instance_class         = "db.t3.micro"  # Small instance for staging
  db_parameter_group_family = "postgres15"
  
  db_name     = "gogsapp"
  db_username = get_env("TF_VAR_db_username", "admin")
  db_password = get_env("TF_VAR_db_password", "CHANGE_ME_IN_CI")
  db_port     = 5432
  
  # Storage configuration
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  
  # Staging-specific settings
  multi_az                 = false  # Single AZ for staging
  backup_retention_period  = 7
  deletion_protection      = false
  skip_final_snapshot      = true
  
  # Monitoring
  performance_insights_enabled = true
  monitoring_interval          = 60
  auto_minor_version_upgrade   = true
}
