#------------------------------------------------------------------------------
# EC2 Splunk Module - Staging Environment
#------------------------------------------------------------------------------

# Include the root terragrunt.hcl configuration
include "root" {
  path = find_in_parent_folders()
}

# Use the EC2 Splunk module
terraform {
  source = "../../../../modules//ec2-splunk"
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

dependency "ecs" {
  config_path = "../ecs"
  
  # Mock outputs for plan without apply
  mock_outputs = {
    ecs_security_group_id = "sg-mock12345"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "secrets_manager" {
  config_path = "../secrets-manager"
  
  # Mock outputs for plan without apply
  mock_outputs = {
    all_secret_arns = ["arn:aws:secretsmanager:us-east-1:123456789:secret:mock"]
    splunk_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789:secret:mock-splunk"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Module-specific inputs
inputs = {
  vpc_id            = dependency.vpc.outputs.vpc_id
  subnet_id         = dependency.vpc.outputs.public_subnet_ids[0]  # Public subnet for Splunk Web access
  availability_zone = local.region_vars.locals.availability_zones[0]
  
  # Instance configuration - smaller for staging
  instance_type = "t3.medium"
  
  # AMI - Amazon Linux 2 (update with latest AMI ID for your region)
  ami_id = get_env("TF_VAR_splunk_ami_id", "ami-0c7217cdde317cfec")  # Amazon Linux 2 in us-east-1
  
  # Volume configuration
  root_volume_size = 30
  data_volume_size = 50
  data_volume_type = "gp3"
  
  # Network access
  allowed_cidr_blocks    = [get_env("TF_VAR_allowed_cidr", "0.0.0.0/0")]  # Restrict in production!
  ecs_security_group_ids = [dependency.ecs.outputs.ecs_security_group_id]
  
  # SSH access - must be explicitly set for security
  enable_ssh      = true
  ssh_cidr_blocks = get_env("TF_VAR_ssh_cidr", null) != null ? [get_env("TF_VAR_ssh_cidr")] : []  # Must be set explicitly - do not use 0.0.0.0/0!
  ssh_public_key  = get_env("TF_VAR_ssh_public_key", null)
  
  # Secrets Manager access
  secrets_manager_arns = dependency.secrets_manager.outputs.all_secret_arns
  
  # Create Elastic IP for stable access
  create_elastic_ip = true
}
