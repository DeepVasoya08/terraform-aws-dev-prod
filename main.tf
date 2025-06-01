terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# This allows us to check if the key files already exist locally
locals {
  private_key_file   = "${path.module}/terraform-key.pem" # change to the project name
  public_key_file    = "${path.module}/terraform-key.pub" # change to the project name
  private_key_exists = fileexists(local.private_key_file)
  public_key_exists  = fileexists(local.public_key_file)
}

provider "aws" {
  region     = "ap-south-1"
  access_key = "<your key>"
  secret_key = "<your key>"
}

# Generate a new private key only if it doesn't exist
resource "tls_private_key" "terraform_key" {
  count     = local.private_key_exists ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 2048

  # This prevents recreation of the key if configuration changes
  lifecycle {
    ignore_changes = all
  }
}

# Data source to read the existing public key file if it exists
data "local_file" "existing_public_key" {
  count    = local.public_key_exists ? 1 : 0
  filename = local.public_key_file
}

# Create a key pair in AWS using either the existing or new public key
resource "aws_key_pair" "terraform_key" {
  key_name = "terraform-key"
  public_key = local.public_key_exists ? data.local_file.existing_public_key[0].content : (
    length(tls_private_key.terraform_key) > 0 ? tls_private_key.terraform_key[0].public_key_openssh : ""
  )

  # Prevent recreation when other parts of the config change
  lifecycle {
    ignore_changes = [public_key]
  }
}

# Output the private key to a local file (only if newly created)
resource "local_file" "private_key" {
  count           = local.private_key_exists ? 0 : 1
  content         = tls_private_key.terraform_key[0].private_key_pem
  filename        = local.private_key_file
  file_permission = "0400"
}

# Save public key to a file as well (only if newly created)
resource "local_file" "public_key" {
  count           = local.public_key_exists ? 0 : 1
  content         = tls_private_key.terraform_key[0].public_key_openssh
  filename        = local.public_key_file
  file_permission = "0644"
}

# Outputs for easy access to the keys (if newly created)
output "key_created" {
  value = local.private_key_exists ? "Using existing key from ${local.private_key_file}" : "New key created and saved to ${local.private_key_file}"
}

module "dev" {
  source   = "./dev"
  key_name = aws_key_pair.terraform_key.key_name
}

module "prod" {
  source   = "./prod"
  key_name = aws_key_pair.terraform_key.key_name
}
