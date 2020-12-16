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
    ServiceProvider = "Antonio"
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
    key     = "terraform.development.300jenkins.tfstate"
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

# 200eks
data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket  = "162198556136-build-state-bucket-antonio-appmod-fin"
    key     = "terraform.development.200eks.tfstate"
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
  cluster_id      = data.terraform_remote_state.eks.outputs.cluster_id
}

data "aws_caller_identity" "current" {}

###############################################################################
# Setup Jenkins Pod
###############################################################################
provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

data "aws_eks_cluster" "cluster" {
  name = local.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_id
}

resource "kubectl_manifest" "jenkins-ns" {
  yaml_body = file("jenkins/jenkins.ns.yaml")
}

resource "kubectl_manifest" "jenkins-pv" {
  yaml_body = templatefile("jenkins/jenkins.pv.yaml", { efs_id = local.efs_id })
}

resource "kubectl_manifest" "jenkins-pvc" {
  yaml_body  = file("jenkins/jenkins.pvc.yaml")
  depends_on = [kubectl_manifest.jenkins-ns, kubectl_manifest.jenkins-pv]
}

resource "kubectl_manifest" "jenkins-rbac" {
  yaml_body  = file("jenkins/jenkins.rbac.yaml")
  depends_on = [kubectl_manifest.jenkins-pvc]
}

resource "kubectl_manifest" "jenkins-deployment" {
  yaml_body  = file("jenkins/jenkins.deployment.yaml")
  depends_on = [kubectl_manifest.jenkins-rbac]
}
