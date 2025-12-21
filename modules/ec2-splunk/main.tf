terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#------------------------------------------------------------------------------
# EC2 Splunk Module - Monitoring Server
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Locals
#------------------------------------------------------------------------------

locals {
  default_user_data = <<-EOF
    #!/bin/bash
    # Minimal bootstrap script - actual Splunk configuration handled by Ansible
    yum update -y
    yum install -y python3
  EOF
}

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#------------------------------------------------------------------------------
# IAM Role for EC2 Instance
#------------------------------------------------------------------------------

resource "aws_iam_role" "splunk" {
  name = "${var.project_name}-${var.environment}-splunk-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_instance_profile" "splunk" {
  name = "${var.project_name}-${var.environment}-splunk-profile"
  role = aws_iam_role.splunk.name
}

# Policy for CloudWatch Logs access
resource "aws_iam_role_policy" "splunk_cloudwatch" {
  name = "${var.project_name}-${var.environment}-splunk-cloudwatch-policy"
  role = aws_iam_role.splunk.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy to read secrets from Secrets Manager
resource "aws_iam_role_policy" "splunk_secrets" {
  name = "${var.project_name}-${var.environment}-splunk-secrets-policy"
  role = aws_iam_role.splunk.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.secrets_manager_arns
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Security Group for Splunk
#------------------------------------------------------------------------------

resource "aws_security_group" "splunk" {
  name        = "${var.project_name}-${var.environment}-splunk-sg"
  description = "Security group for Splunk EC2 instance"
  vpc_id      = var.vpc_id

  # Splunk Web UI
  ingress {
    description = "Splunk Web UI"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Splunk Management Port
  ingress {
    description = "Splunk Management Port"
    from_port   = 8089
    to_port     = 8089
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Splunk HEC (HTTP Event Collector)
  ingress {
    description     = "Splunk HEC from ECS"
    from_port       = 8088
    to_port         = 8088
    protocol        = "tcp"
    security_groups = var.ecs_security_group_ids
  }

  # SSH access (restricted)
  dynamic "ingress" {
    for_each = var.enable_ssh ? [1] : []
    content {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-splunk-sg"
  })
}

#------------------------------------------------------------------------------
# EC2 Key Pair (optional)
#------------------------------------------------------------------------------

resource "aws_key_pair" "splunk" {
  count      = var.ssh_public_key != null ? 1 : 0
  key_name   = "${var.project_name}-${var.environment}-splunk-key"
  public_key = var.ssh_public_key

  tags = var.tags
}

#------------------------------------------------------------------------------
# EBS Volume for Splunk Data
#------------------------------------------------------------------------------

resource "aws_ebs_volume" "splunk_data" {
  availability_zone = var.availability_zone
  size              = var.data_volume_size
  type              = var.data_volume_type
  iops              = var.data_volume_type == "io1" || var.data_volume_type == "io2" ? var.data_volume_iops : null
  throughput        = var.data_volume_type == "gp3" ? var.data_volume_throughput : null
  encrypted         = true
  kms_key_id        = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-splunk-data"
    }
  )
}

#------------------------------------------------------------------------------
# EC2 Instance for Splunk
#------------------------------------------------------------------------------

resource "aws_instance" "splunk" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.splunk.id]
  iam_instance_profile   = aws_iam_instance_profile.splunk.name
  key_name               = var.ssh_public_key != null ? aws_key_pair.splunk[0].key_name : null
  user_data              = var.user_data != null ? var.user_data : local.default_user_data
  monitoring             = true # Enable detailed monitoring

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = var.kms_key_id
  }

  # Enable EBS optimization for better performance
  ebs_optimized = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-splunk"
    }
  )

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

#------------------------------------------------------------------------------
# Attach Data Volume
# NOTE: Device name /dev/sdf may be mapped differently on newer instance types.
# On nitro-based instances, this typically appears as /dev/nvme1n1.
# Check instance metadata or use lsblk to verify the actual device name.
#------------------------------------------------------------------------------

resource "aws_volume_attachment" "splunk_data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.splunk_data.id
  instance_id = aws_instance.splunk.id
}

#------------------------------------------------------------------------------
# Elastic IP (optional)
#------------------------------------------------------------------------------

resource "aws_eip" "splunk" {
  count    = var.create_elastic_ip ? 1 : 0
  instance = aws_instance.splunk.id
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-splunk-eip"
  })
}
