variable "project_name" {
  description = "Project name prefix used for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment identifier (e.g. dev, prod)."
  type        = string
}

variable "service_names" {
  description = "Names of the services that need ECR repositories. One repository is created per name."
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "Whether image tags can be overwritten. IMMUTABLE prevents tag reuse, which is required for GitOps image-tag-bump workflows."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Whether to scan images for vulnerabilities when pushed."
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Number of most recent images to retain. Older images are deleted by the lifecycle policy."
  type        = number
  default     = 10
}

variable "tags" {
  description = "Additional tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
