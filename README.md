# aws-gitops-platform-config

Platform configuration and infrastructure-as-code for a GitOps-driven Kubernetes platform on AWS. This repo is the single source of truth for cluster state. ArgoCD watches it and syncs the cluster automatically.

The application source lives in the companion repo: [aws-gitops-platform-app](https://github.com/selimcelem/aws-gitops-platform-app).

## What this repo contains

- **Terraform modules** under infrastructure/modules/ that provision VPC, EKS, ECR, RDS, SQS, IAM with IRSA, and ArgoCD itself via Helm.
- **Helm charts** under charts/ for the API and worker services.
- **Kustomize overlays** under kustomize/ for environment-specific configuration (dev and prod).
- **ArgoCD application manifests** under argocd/applications/.
- **Observability stack configuration** under observability/ for Prometheus and Grafana.

## Deployment flow

1. terraform apply provisions the AWS platform and installs ArgoCD on the cluster.
2. ArgoCD reads application manifests from argocd/applications/.
3. ArgoCD deploys each service via its Helm chart, with values resolved from the active Kustomize overlay.
4. On any push to main that changes a manifest, ArgoCD reconciles within minutes.

## Repository layout

```
aws-gitops-platform-config/
├── argocd/applications/      # ArgoCD Application CRDs
├── charts/
│   ├── api/                  # Helm chart for API service
│   └── worker/               # Helm chart for worker service
├── infrastructure/
│   └── modules/
│       ├── argocd/           # ArgoCD via helm_release
│       ├── ecr/              # One repo per service
│       ├── eks/              # Cluster + managed node group
│       ├── iam/              # IRSA roles, OIDC provider
│       ├── rds/              # PostgreSQL, single AZ, smallest instance
│       ├── sqs/              # Job queue
│       └── vpc/              # 3 public, 3 private subnets, NAT
├── kustomize/
│   ├── base/                 # Shared resources
│   └── overlays/
│       ├── dev/              # Active environment
│       └── prod/             # Pattern only, not deployed
└── observability/
    ├── grafana/              # Dashboards as code
    └── prometheus/           # Scrape config and values
```

## Region

eu-west-1.

## Cost posture

All infrastructure is created with terraform apply and torn down with terraform destroy after every working session. RDS uses the smallest available instance class in single AZ.

## Status

Project scaffolded. Infrastructure modules in progress.
