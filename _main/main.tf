###############################################################################
# Providers
###############################################################################
provider "aws" {
  region              = var.region
  allowed_account_ids = [var.aws_account_id]
}

###############################################################################
# Terraform main config
# terraform block cannot be interpolated; sample provided as output of _main
# `terraform output remote_state_configuration_example`
###############################################################################
terraform {
  required_version = ">= 0.14"
  required_providers {
      aws = {
        version = "~> 2.0"
      }
  }
}

###############################################################################
# Data Sources and Locals
###############################################################################
data "aws_caller_identity" "current" {}

# Remote State Locals
locals {
  tags = {
    Environment       = var.environment
    ServiceProvider  = "Rackspace"
    Terraform         = "true"
    appid-or-sso      = var.appid-or-sso
    tag-std           = "v1.0"
    needed-until-date = "2020-12-31"
  }
}
###############################################################################
# S3 Bucket for Terraform state
###############################################################################
resource "aws_s3_bucket" "state" {
  bucket        = "${data.aws_caller_identity.current.account_id}-build-state-bucket-antonio-appmod-fin"
  force_destroy = true

  tags = local.tags

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
