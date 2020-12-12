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

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#   token                  = data.aws_eks_cluster_auth.cluster.token
#   load_config_file       = false
# }
#
# data "aws_eks_cluster" "cluster" {
#   name = module.eks.cluster_id
# }
#
# data "aws_eks_cluster_auth" "cluster" {
#   name = module.eks.cluster_id
# }

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
    key     = "terraform.development.100eks.tfstate"
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

# Remote State Locals
locals {
  vpc_id          = data.terraform_remote_state.base_network.outputs.base_network.vpc_id
  private_subnets = data.terraform_remote_state.base_network.outputs.base_network.private_subnets
  public_subnets  = data.terraform_remote_state.base_network.outputs.base_network.public_subnets
}

data "aws_caller_identity" "current" {}

###############################################################################
# Security Groups
###############################################################################
resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id      = local.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = local.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
}

###############################################################################
# EKS
###############################################################################
