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
    aws = "~> 3.6.0"
  }

  backend "s3" {
    # Get S3 Bucket name from layer _main (`terraform output state_bucket_id`)
    bucket = "162198556136-build-state-bucket-antonio-appmod-eks-helm"
    # This key must be unique for each layer!
    key     = "terraform.development.300eks.tfstate"
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
    bucket  = "162198556136-build-state-bucket-antonio-appmod-eks-helm"
    key     = "terraform.development.000base.tfstate"
    region  = "ap-southeast-2"
    encrypt = "true"
  }
}

# 200compute
data "terraform_remote_state" "compute" {
  backend = "s3"

  config = {
    bucket  = "162198556136-build-state-bucket-antonio-appmod-eks-helm"
    key     = "terraform.development.200compute.tfstate"
    region  = "ap-southeast-2"
    encrypt = "true"
  }
}

# Remote State Locals
locals {
  vpc_id          = data.terraform_remote_state.base_network.outputs.base_network.vpc_id
  private_subnets = data.terraform_remote_state.base_network.outputs.base_network.private_subnets
  public_subnets  = data.terraform_remote_state.base_network.outputs.base_network.public_subnets
  PrivateAZ1      = data.terraform_remote_state.base_network.outputs.base_network.private_subnets[0]
  PrivateAZ2      = data.terraform_remote_state.base_network.outputs.base_network.private_subnets[1]
  PublicAZ1       = data.terraform_remote_state.base_network.outputs.base_network.public_subnets[0]
  PublicAZ2       = data.terraform_remote_state.base_network.outputs.base_network.public_subnets[1]
}

data "aws_caller_identity" "current" {}

##############################################


resource "aws_iam_policy" "autoscaler_policy" {
  name        = "autoscaler"
  path        = "/"
  description = "Autoscaler bots are fully allowed to read/run autoscaling groups"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
    "Action": [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions"
    ],
    "Resource": "*",
    "Effect": "Allow"
    }
  ]
}
EOF
}

##############################################


# static config of k8s provider - TMP
# provider "kubernetes" {
#   host = module.eks.cluster_endpoint
#   load_config_file = true
#   # kubeconfig file relative to path where you execute tf, in my case it is the same dir
#   config_path      = "kubeconfig_${local.cluster_name}"
#   version = "~> 1.9"
# }

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "13.2.1"

  cluster_name    = "eks-test"
  cluster_version = "1.17"
  subnets         = local.public_subnets
  vpc_id          = local.vpc_id

  worker_groups_launch_template = [
    {
      name                 = "worker-group-1"
      instance_type        = "t3.large"
      asg_desired_capacity = 2
      asg_max_size         = 5
      asg_min_size         = 2
      autoscaling_enable   = true
      public_ip            = true
    }
  ]

  workers_additional_policies = [
    aws_iam_policy.autoscaler_policy.arn
  ]
}


data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

# dynamic
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11"
}
#
# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "12.0.0"
#   # insert the 4 required variables here
#   cluster_name = "${local.cluster_name}"
#   subnets = module.vpc.public_subnets
#   vpc_id = module.vpc.vpc_id
#   map_users = var.map_users
#   # worker nodes
#   worker_groups_launch_template = [
#     {
#       name                 = "worker-group-1"
#       instance_type        = "t3.large"
#       asg_desired_capacity = 2
#       asg_max_size = 5
#       asg_min_size  = 2
#       autoscaling_enabled = true
#       public_ip            = true
#     }
#   ]
#
# }
