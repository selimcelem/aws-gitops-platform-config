variable "project_name" {
  description = "Project name prefix used for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment identifier (e.g. dev, prod)."
  type        = string
}

variable "aws_region" {
  description = "AWS region the resources are created in."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS cluster OIDC provider. Comes from the EKS module."
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the EKS cluster OIDC provider (without the https:// prefix). Comes from the EKS module."
  type        = string
}

variable "service_namespace" {
  description = "Kubernetes namespace where the service ServiceAccounts live."
  type        = string
  default     = "default"
}

variable "sqs_job_queue_arn" {
  description = "ARN of the SQS job queue. Leave empty if the SQS module is not yet deployed; SQS permissions will not be attached."
  type        = string
  default     = ""
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding database credentials. Leave empty if the RDS module is not yet deployed; Secrets Manager permissions will not be attached."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
