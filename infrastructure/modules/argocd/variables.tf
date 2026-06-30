variable "project_name" {
  description = "Project name prefix used for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment identifier (e.g. dev, prod)."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace ArgoCD is installed into."
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Version of the argo-cd Helm chart to install."
  type        = string
  default     = "10.0.1"
}

variable "tags" {
  description = "Additional tags. ArgoCD runs in-cluster so these are informational only; Kubernetes resources do not carry AWS tags."
  type        = map(string)
  default     = {}
}
