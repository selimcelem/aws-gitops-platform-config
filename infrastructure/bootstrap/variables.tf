variable "aws_region" {
  description = "AWS region for the bootstrap resources."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name prefix used for resource naming."
  type        = string
  default     = "gitops-platform"
}

variable "tags" {
  description = "Common tags applied to all bootstrap resources."
  type        = map(string)
  default = {
    Project   = "gitops-platform"
    ManagedBy = "terraform"
    Component = "bootstrap"
  }
}
