#------------------------------------------------------------------------------
# RDS Module - Production Environment
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
  
  # Allow access from ECS security group
  allowed_security_groups = []  # Will be updated via data source in ECS module
  
  # Database configuration - larger for production
  db_engine                 = "postgres"
  db_engine_version         = "15.4"
  db_instance_class         = "db.t3.medium"  # Larger instance for production
  db_parameter_group_family = "postgres15"
  
  db_name     = "gogsapp"
  db_username = get_env("TF_VAR_db_username", "admin")
  db_password = get_env("TF_VAR_db_password", "CHANGE_ME_IN_CI")
  db_port     = 5432
  
  # Storage configuration - larger for production
  allocated_storage     = 50
  max_allocated_storage = 200
  storage_type          = "gp3"
  
  # Production-specific settings
  multi_az                 = true   # High availability for production
  backup_retention_period  = 30     # Longer retention for production
  deletion_protection      = true   # Prevent accidental deletion
  skip_final_snapshot      = false  # Always take final snapshot
  
  # Monitoring
  performance_insights_enabled = true
  monitoring_interval          = 60
  auto_minor_version_upgrade   = true
  
  # Maintenance windows - off-peak hours
  backup_window      = "03:00-04:00"
  maintenance_window = "Mon:04:00-Mon:05:00"
}
