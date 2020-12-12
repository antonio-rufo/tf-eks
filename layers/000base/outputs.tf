###############################################################################
# Base Network Output
###############################################################################
output "vpc_id" {
  description = "The ID of the VPC."
  value       = module.base_network.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets."
  value       = module.base_network.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets."
  value       = module.base_network.public_subnets
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC."
  value       = module.base_network.vpc_cidr_block
}
