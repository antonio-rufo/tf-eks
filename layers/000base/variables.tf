###############################################################################
# Variables - Environment
###############################################################################
variable "aws_account_id" {
  description = "AWS Account ID"
}

variable "region" {
  description = "Default Region"
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Name of the environment for the deployment, e.g. Integration, PreProduction, Production, QA, Staging, Test"
  default     = "Development"
}

variable "env" {
  description = "Short environment variable, e.g. Dev, Prod, Test"
  default     = "Dev"
}

###############################################################################
# Variables - Base Network
###############################################################################
variable "vpc_name" {
  description = "Name for the VPC	"
  default     = "BaseNetwork"
}

variable "cidr_range" {
  description = "CIDR range for the VPC"
}

variable "private_cidr_ranges" {
  description = "An array of CIDR ranges to use for private subnets"
  type        = list(string)
}

variable "public_cidr_ranges" {
  description = "An array of CIDR ranges to use for public subnets"
  type        = list(string)
}

###############################################################################
# Variables - EKS
###############################################################################
variable "cluster_name" {
  description = "EKS Cluster name"
}
