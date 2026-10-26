terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# AMI oficial más reciente de Amazon Linux 2023 (x86_64).
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

locals {
  common_tags = {
    Project     = "pt1-4-ex1"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Dos instancias EC2 idénticas; solo cambia su etiqueta Name.
resource "aws_instance" "web" {
  count = 2

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  tags = merge(
    local.common_tags,
    {
      Name = "Instancia-${count.index + 1}"
    }
  )
}

output "instance_ids" {
  description = "IDs de las instancias EC2 creadas."
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "Direcciones IP públicas de las instancias EC2."
  value       = aws_instance.web[*].public_ip
}
