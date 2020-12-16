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

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }

  backend "s3" {
    # Get S3 Bucket name from layer _main (`terraform output state_bucket_id`)
    bucket = "162198556136-build-state-bucket-antonio-appmod-fin"
    # This key must be unique for each layer!
    key     = "terraform.development.200eks.tfstate"
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
data "terraform_remote_state" "efs" {
  backend = "s3"

  config = {
    bucket  = "162198556136-build-state-bucket-antonio-appmod-fin"
    key     = "terraform.development.100efs.tfstate"
    region  = "ap-southeast-2"
    encrypt = "true"
  }
}

# Remote State Locals
locals {
  vpc_id          = data.terraform_remote_state.base_network.outputs.vpc_id
  private_subnets = data.terraform_remote_state.base_network.outputs.private_subnets
  public_subnets  = data.terraform_remote_state.base_network.outputs.public_subnets
  efs_id          = data.terraform_remote_state.efs.outputs.efs_id
  efs_sg_id       = data.terraform_remote_state.efs.outputs.efs_sg_id
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
      "0.0.0.0/0",
    ]
  }
}

# resource "aws_security_group" "all_worker_mgmt" {
#   name_prefix = "all_worker_management"
#   vpc_id      = local.vpc_id
#
#   ingress {
#     from_port = 22
#     to_port   = 22
#     protocol  = "tcp"
#
#     cidr_blocks = [
#       "10.0.0.0/8",
#       "172.16.0.0/12",
#       "192.168.0.0/16",
#       "0.0.0.0/0",
#     ]
#   }
# }

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

###############################################################################
# EKS
###############################################################################
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = "1.18"
  subnets         = local.private_subnets
  version         = "13.2.1"

  cluster_create_timeout          = "1h"
  cluster_endpoint_private_access = true

  vpc_id = local.vpc_id

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.small"
      additional_userdata           = "echo foo bar"
      asg_desired_capacity          = 2
      asg_max_size                  = 5
      asg_min_size                  = 2
      autoscaling_enabled           = true
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
      public_ip                     = true
    },
  ]

  workers_additional_policies = [
  aws_iam_policy.autoscaler_policy.arn
]

  # worker_additional_security_group_ids = [aws_security_group.all_worker_mgmt.id]
  # map_roles                            = var.map_roles
  # map_users                            = var.map_users
  # map_accounts                         = var.map_accounts
}

###############################################################################
# Setup Kubeconfig
###############################################################################
resource "null_resource" "update-kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.cluster_name}"
  }
  depends_on = [module.eks]
}

###############################################################################
# Setup EFS Driver
###############################################################################
resource "null_resource" "apply-efs-driver" {
  provisioner "local-exec" {
    command = "kubectl apply -k 'github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=release-1.0'"
  }
  depends_on = [null_resource.update-kubeconfig]
}

# provider "kubectl" {
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#   token                  = data.aws_eks_cluster_auth.cluster.token
#   load_config_file       = false
# }
#
# resource "kubectl_manifest" "jenkins-ns" {
#     yaml_body = file("../300jenkins/jenkins.ns.yaml")
#     depends_on = [module.eks]
# }
#
# resource "kubectl_manifest" "jenkins-pv" {
#     yaml_body = templatefile("../300jenkins/jenkins.pv.yaml", {efs_id = aws_efs_file_system.eks_efs.id })
# }
#
# resource "kubectl_manifest" "jenkins-pvc" {
#     yaml_body = file("../300jenkins/jenkins.pvc.yaml")
#     depends_on = [kubectl_manifest.jenkins-ns, kubectl_manifest.jenkins-pv]
# }
#
# resource "kubectl_manifest" "jenkins-rbac" {
#     yaml_body = file("../300jenkins/jenkins.rbac.yaml")
#     depends_on = [kubectl_manifest.jenkins-pvc]
# }
#
# resource "kubectl_manifest" "jenkins-deployment" {
#     yaml_body = file("../300jenkins/jenkins.deployment.yaml")
#     depends_on = [kubectl_manifest.jenkins-rbac]
# }

###############################################################################
# EFS
###############################################################################
resource "aws_security_group_rule" "efs_tcp_2049_eks_worker_nodes_sg" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = module.eks.worker_security_group_id
  security_group_id        = local.efs_sg_id
  description              = "Ingress from EKS Worker Nodes (TCP:2049)"
}

resource "aws_security_group_rule" "efs_tcp_2049_eks_primary_cluster_sg" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = module.eks.cluster_primary_security_group_id
  security_group_id        = local.efs_sg_id
  description              = "Ingress from EKS Primary Cluster (TCP:2049)"
}

resource "aws_security_group_rule" "efs_tcp_2049_eks_cluster_sg" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = module.eks.cluster_security_group_id
  security_group_id        = local.efs_sg_id
  description              = "Ingress from EKS Cluster (TCP:2049)"
}
