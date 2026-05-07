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
