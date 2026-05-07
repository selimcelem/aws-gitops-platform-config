variable "project_name" {
  description = "Project name prefix used for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment identifier (e.g. dev, prod)."
  type        = string
}

variable "aws_region" {
  description = "AWS region the VPC is created in."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to span. Must be 2 or 3 for EKS production-grade layouts."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "single_nat_gateway" {
  description = "If true, create one NAT Gateway shared across all private subnets (cheaper, no HA). If false, create one NAT Gateway per AZ (production-grade HA)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
