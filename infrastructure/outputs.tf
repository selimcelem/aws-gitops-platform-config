# Platform-wide outputs.
# Module outputs are exposed here as modules are wired in.

output "vpc_id" {
  description = "ID of the platform VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (for EKS nodes, RDS, pods)."
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs (for ALBs)."
  value       = module.vpc.public_subnet_ids
}

output "availability_zones" {
  description = "Availability zones the VPC spans."
  value       = module.vpc.availability_zones
}
