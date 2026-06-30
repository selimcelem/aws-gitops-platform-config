locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# Namespace for ArgoCD
# -----------------------------------------------------------------------------
# Created explicitly rather than relying on the Helm chart's create_namespace
# so the namespace lifecycle is visible in Terraform state and can carry
# labels if needed later.

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = local.name_prefix
    }
  }
}

# -----------------------------------------------------------------------------
# ArgoCD Helm release
# -----------------------------------------------------------------------------
# Installs the community argo-cd chart in its non-HA form. The UI is reached
# via "kubectl port-forward" rather than a public LoadBalancer, which keeps
# the install free and avoids exposing ArgoCD to the internet in a dev setup.

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version

  # Wait for all components to become ready before marking the release created.
  wait    = true
  timeout = 600

  # Keep the server as a ClusterIP service (default). No public exposure.
  set = [
    {
      name  = "server.service.type"
      value = "ClusterIP"
    },
    {
      name  = "configs.params.server\\.insecure"
      value = "true"
    }
  ]
}
