###############################################################################
######################### 300eks Layer  #########################
###############################################################################

###############################################################################
# Providers
###############################################################################
provider "aws" {
  region              = var.region
  allowed_account_ids = [var.aws_account_id]
}

locals {
  tags = {
    Environment     = var.environment
    ServiceProvider = "Rackspace"
  }
}

###############################################################################
# Terraform main config
# terraform block cannot be interpolated; sample provided as output of _main
# `terraform output remote_state_configuration_example`
###############################################################################
terraform {
  required_version = ">= 0.14"
  required_providers {
    aws        = "~> 3.6.0"
    kubernetes = "~> 1.11"
  }

  backend "s3" {
    # Get S3 Bucket name from layer _main (`terraform output state_bucket_id`)
    bucket = "162198556136-build-state-bucket-antonio-appmod-fin"
    # This key must be unique for each layer!
    key     = "terraform.development.200efs.tfstate"
    region  = "ap-southeast-2"
    encrypt = "true"
  }
}

###############################################################################
# Terraform Remote State
###############################################################################
# _main
data "terraform_remote_state" "main_state" {
  backend = "local"

  config = {
    path = "../../_main/terraform.tfstate"
  }
}

# Remote State Locals
locals {
  state_bucket_id = data.terraform_remote_state.main_state.outputs.state_bucket_id
}

# 000base
data "terraform_remote_state" "base_network" {
  backend = "s3"

  config = {
    bucket  = "162198556136-build-state-bucket-antonio-appmod-fin"
    key     = "terraform.development.000base.tfstate"
    region  = "ap-southeast-2"
    encrypt = "true"
  }
}

# 100efs
data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket  = "162198556136-build-state-bucket-antonio-appmod-fin"
    key     = "terraform.development.100eks.tfstate"
    region  = "ap-southeast-2"
    encrypt = "true"
  }
}

# Remote State Locals
locals {
  vpc_id           = data.terraform_remote_state.base_network.outputs.vpc_id
  private_subnets  = data.terraform_remote_state.base_network.outputs.private_subnets
  public_subnets   = data.terraform_remote_state.base_network.outputs.public_subnets
  vpc_cidr         = data.terraform_remote_state.base_network.outputs.vpc_cidr
  cluster_endpoint = data.terraform_remote_state.eks.outputs.cluster_endpoint
}

data "aws_caller_identity" "current" {}

###############################################################################
# Security Groups
###############################################################################
resource "aws_security_group" "efs_sg" {
  name_prefix = "efs-sg"
  vpc_id      = local.vpc_id

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"

    cidr_blocks = [local.vpc_cidr]
  }
}

###############################################################################
# EFS
###############################################################################
resource "aws_efs_file_system" "eks_efs" {
  creation_token = "eks-efs"
  encrypted      = true

  tags = {
    Name = "EKS-EFS"
  }
}

resource "aws_efs_mount_target" "eks_efs_mount_point" {
  file_system_id  = aws_efs_file_system.eks_efs.id
  subnet_id       = local.private_subnets[0]
  security_groups = [aws_security_group.efs_sg.id]
}
