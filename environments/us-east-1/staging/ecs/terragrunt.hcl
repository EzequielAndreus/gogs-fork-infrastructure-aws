#------------------------------------------------------------------------------
# ECS Module - Staging Environment
#------------------------------------------------------------------------------

# Include the root terragrunt.hcl configuration
include "root" {
  path = find_in_parent_folders()
}

# Use the ECS module
terraform {
  source = "../../../../modules//ecs"
}

# Load region-level variables
locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

# Dependencies
dependency "vpc" {
  config_path = "../vpc"
  
  # Mock outputs for plan without apply
  mock_outputs = {
    vpc_id             = "vpc-mock12345"
    public_subnet_ids  = ["subnet-mock1", "subnet-mock2"]
    private_subnet_ids = ["subnet-mock3", "subnet-mock4"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "secrets_manager" {
  config_path = "../secrets-manager"
  
  # Mock outputs for plan without apply
  mock_outputs = {
    all_secret_arns      = ["arn:aws:secretsmanager:us-east-1:123456789:secret:mock"]
    database_secret_arn  = "arn:aws:secretsmanager:us-east-1:123456789:secret:mock-db"
    application_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789:secret:mock-app"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "rds" {
  config_path = "../rds"
  
  # Mock outputs for plan without apply
  mock_outputs = {
    db_instance_endpoint = "mock-db.example.com:5432"
    db_instance_address  = "mock-db.example.com"
    db_instance_port     = 5432
    db_name              = "gogsapp"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Module-specific inputs
inputs = {
  aws_region         = local.region_vars.locals.aws_region
  vpc_id             = dependency.vpc.outputs.vpc_id
  public_subnet_ids  = dependency.vpc.outputs.public_subnet_ids
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  
  # Docker image from DockerHub - Replace with your actual image
  docker_image   = get_env("TF_VAR_docker_image", "your-dockerhub-username/your-app:latest")
  container_name = "gogs-app"
  container_port = 8080
  
  # Task configuration - smaller for staging
  task_cpu    = 256
  task_memory = 512
  
  # Desired count
  desired_count = 1
  
  # Health check
  health_check_path = "/health"
  
  # Environment variables
  environment_variables = [
    {
      name  = "ENVIRONMENT"
      value = "staging"
    },
    {
      name  = "DB_HOST"
      value = dependency.rds.outputs.db_instance_address
    },
    {
      name  = "DB_PORT"
      value = tostring(dependency.rds.outputs.db_instance_port)
    },
    {
      name  = "DB_NAME"
      value = dependency.rds.outputs.db_name
    }
  ]
  
  # Secrets from Secrets Manager
  secrets = [
    {
      name      = "DB_USERNAME"
      valueFrom = "${dependency.secrets_manager.outputs.database_secret_arn}:username::"
    },
    {
      name      = "DB_PASSWORD"
      valueFrom = "${dependency.secrets_manager.outputs.database_secret_arn}:password::"
    }
  ]
  
  # Secrets Manager ARNs for IAM policy
  secrets_manager_arns = dependency.secrets_manager.outputs.all_secret_arns
  
  # Container Insights
  enable_container_insights = true
  log_retention_days        = 14
  
  # Auto scaling
  enable_autoscaling = true
  min_capacity       = 1
  max_capacity       = 2
  cpu_target_value   = 70
}
