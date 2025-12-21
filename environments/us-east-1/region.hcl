#------------------------------------------------------------------------------
# Region-level Configuration
# Contains settings that apply to the specific AWS region
#------------------------------------------------------------------------------

locals {
  # AWS Region for deployment
  aws_region = "us-east-1"
  
  # Availability zones
  availability_zones = ["us-east-1a", "us-east-1b"]
}
