#------------------------------------------------------------------------------
# EC2 Splunk Module Variables
#------------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EC2 instance will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the EC2 instance and EBS volume"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Amazon Linux 2 recommended)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 50
}

variable "data_volume_size" {
  description = "Size of the data volume for Splunk in GB"
  type        = number
  default     = 100
}

variable "data_volume_type" {
  description = "Type of the data volume (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
}

variable "kms_key_id" {
  description = "KMS key ID for EBS encryption"
  type        = string
  default     = null
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access Splunk Web UI"
  type        = list(string)
  default     = []
}

variable "ecs_security_group_ids" {
  description = "Security group IDs of ECS tasks that send logs to Splunk"
  type        = list(string)
  default     = []
}

variable "enable_ssh" {
  description = "Enable SSH access to the instance"
  type        = bool
  default     = false
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = []
}

variable "ssh_public_key" {
  description = "SSH public key for the key pair"
  type        = string
  default     = null
}

variable "secrets_manager_arns" {
  description = "List of Secrets Manager ARNs that Splunk can access"
  type        = list(string)
  default     = []
}

variable "splunk_download_url" {
  description = "URL to download Splunk Enterprise RPM"
  type        = string
  default     = "https://download.splunk.com/products/splunk/releases/9.1.1/linux/splunk-9.1.1-64e843ea36b1-linux-2.6-x86_64.rpm"
}

variable "splunk_admin_password" {
  description = "Admin password for Splunk"
  type        = string
  sensitive   = true
}

variable "user_data" {
  description = "Custom user data script (overrides default Splunk installation)"
  type        = string
  default     = null
}

variable "create_elastic_ip" {
  description = "Create and associate an Elastic IP"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
