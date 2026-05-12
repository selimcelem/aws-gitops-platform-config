variable "aws_region" {
  description = "AWS region for all platform resources."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name prefix used for all resource naming."
  type        = string
  default     = "gitops-platform"
}

variable "environment" {
  description = "Environment identifier, applied as a tag and used in resource names."
  type        = string
  default     = "dev"
}

variable "cluster_admin_principal_arn" {
  description = "ARN of the IAM user or role to grant EKS cluster-admin access. Set this to your own IAM user ARN so you can kubectl against the cluster."
  type        = string
  default     = ""
}
