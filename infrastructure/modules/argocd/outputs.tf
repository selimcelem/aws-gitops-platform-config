output "namespace" {
  description = "Namespace ArgoCD is installed into."
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "release_name" {
  description = "Name of the ArgoCD Helm release."
  value       = helm_release.argocd.name
}

output "chart_version" {
  description = "Version of the argo-cd Helm chart that was installed."
  value       = helm_release.argocd.version
}

output "server_service" {
  description = "Name of the ArgoCD server Kubernetes service, used for port-forwarding to reach the UI."
  value       = "argocd-server"
}
