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

output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "API server endpoint of the EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "Kubernetes version running on the control plane."
  value       = module.eks.cluster_version
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC provider, for IRSA trust policies."
  value       = module.eks.oidc_provider_arn
}
