variable "project_name" {
  description = "Project name prefix used for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment identifier (e.g. dev, prod)."
  type        = string
}

variable "aws_region" {
  description = "AWS region the cluster is created in."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC the cluster runs in."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the cluster and node group."
  type        = list(string)
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.31"
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of nodes in the managed node group."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes in the managed node group."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes in the managed node group."
  type        = number
  default     = 3
}

variable "cluster_admin_principal_arn" {
  description = "ARN of the IAM principal (user or role) to grant cluster-admin access via EKS access entry. Leave empty to skip."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
