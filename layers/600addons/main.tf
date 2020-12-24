# 600addons

###############################################################################
# Providers
###############################################################################
provider "aws" {
  region              = var.region
  allowed_account_ids = [var.aws_account_id]
}

###############################################################################
# Terraform main config
###############################################################################
terraform {
  required_version = ">= 0.14"
  required_providers {
    aws        = "~> 3.6.0"
  }

  backend "s3" {
    # Get S3 Bucket name from layer _main (`terraform output state_bucket_id`)
    bucket = "162198556136-build-state-bucket-antonio-appmod-fin"
    # This key must be unique for each layer!
    key     = "terraform.development.600addons.tfstate"
    region  = "ap-southeast-2"
    encrypt = "true"
  }
}

###############################################################################
# Data Sources and Locals
###############################################################################
data "aws_caller_identity" "current" {}

# Remote State Locals
locals {
  tags = {
    Environment     = var.environment
    ServiceProvider = "Rackspace"
  }
}

###############################################################################
# CloudTrail
###############################################################################
### To follow

###############################################################################
# CloudWatch
###############################################################################
### To follow

###############################################################################
# Guardduty
###############################################################################
### To follow

###############################################################################
# Config
###############################################################################
### To follow