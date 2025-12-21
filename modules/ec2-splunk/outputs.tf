#------------------------------------------------------------------------------
# EC2 Splunk Module Outputs
#------------------------------------------------------------------------------

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.splunk.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.splunk.arn
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.splunk.private_ip
}

output "public_ip" {
  description = "Public IP address of the instance (if available)"
  value       = var.create_elastic_ip ? aws_eip.splunk[0].public_ip : aws_instance.splunk.public_ip
}

output "private_dns" {
  description = "Private DNS name of the instance"
  value       = aws_instance.splunk.private_dns
}

output "security_group_id" {
  description = "Security group ID for Splunk"
  value       = aws_security_group.splunk.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.splunk.arn
}

output "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  value       = aws_iam_instance_profile.splunk.arn
}

output "splunk_web_url" {
  description = "URL to access Splunk Web UI"
  value       = "http://${var.create_elastic_ip ? aws_eip.splunk[0].public_ip : aws_instance.splunk.private_ip}:8000"
}

output "splunk_hec_endpoint" {
  description = "Splunk HEC endpoint URL (Splunk must be installed and configured by Ansible first)"
  value       = "https://${var.create_elastic_ip ? aws_eip.splunk[0].public_ip : aws_instance.splunk.private_ip}:8088"
}

output "data_volume_id" {
  description = "EBS data volume ID (for Ansible to mount at /opt/splunk)"
  value       = aws_ebs_volume.splunk_data.id
}

output "data_volume_device_name" {
  description = "Device name for data volume (may appear as /dev/nvme1n1 on nitro instances)"
  value       = "/dev/sdf"
}

output "elastic_ip" {
  description = "Elastic IP address (if created)"
  value       = var.create_elastic_ip ? aws_eip.splunk[0].public_ip : null
}
