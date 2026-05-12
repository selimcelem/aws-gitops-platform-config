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
├── argocd/applications/              # ArgoCD Application CRDs
├── charts/
│   ├── api/                          # Helm chart for API service
│   └── worker/                       # Helm chart for worker service
├── docs/
│   ├── adr/                          # Architecture Decision Records
│   └── screenshots/                  # Console evidence for deployed modules
├── infrastructure/
│   ├── main.tf, variables.tf, outputs.tf   # Root config, S3 backend
│   ├── .terraform.lock.hcl           # Provider version pins (committed)
│   ├── bootstrap/                    # S3 state backend, separate lifecycle
│   └── modules/
│       ├── argocd/                   # ArgoCD via helm_release
│       ├── ecr/                      # One repo per service
│       ├── eks/                      # Cluster + managed node group
│       ├── iam/                      # IRSA roles, OIDC provider
│       ├── rds/                      # PostgreSQL, single AZ, smallest instance
│       ├── sqs/                      # Job queue
│       └── vpc/                      # 3 public, 3 private subnets, NAT
├── kustomize/
│   ├── base/                         # Shared resources
│   └── overlays/
│       ├── dev/                      # Active environment
│       └── prod/                     # Pattern only, not deployed
└── observability/
    ├── grafana/                      # Dashboards as code
    └── prometheus/                   # Scrape config and values
```

## Region

eu-west-1.

## Cost posture

All infrastructure is created with terraform apply and torn down with terraform destroy after every working session. RDS uses the smallest available instance class in single AZ.

## Status

The VPC and EKS modules are implemented and verified end-to-end against AWS (deployment evidence under docs/screenshots/). The remaining infrastructure modules (ECR, IAM, RDS, SQS, ArgoCD) are scaffolded and in progress.

## Architecture decisions

### ArgoCD: self-installed via Terraform helm_release

ArgoCD is installed onto the EKS cluster via Terraform `helm_release` rather than the AWS-managed EKS Capability for ArgoCD (launched November 2025). The managed capability is the right choice for production teams who want AWS to own the SLA and patching, but for this project I install it myself for three reasons: it demonstrates real platform engineering work, it avoids the per-hour capability cost on top of EKS, and it keeps the entire platform reproducible from a single `terraform apply` without requiring AWS Identity Center setup.

### CI/CD: two pipelines, separated by trigger

Two GitHub Actions workflows, one per repo:

- **App repo** (`build-and-push.yml`): triggered by changes to application code or Dockerfiles. Builds the image, pushes to ECR, and updates the image tag in this config repo to trigger ArgoCD sync.
- **Config repo** (`terraform.yml`): triggered by changes to `infrastructure/**`. Runs `terraform plan` on PRs and `terraform apply` on merge to main.

This separation means a Terraform typo never rebuilds containers, and a code change never runs `terraform apply`. Each pipeline does only what its trigger demands.

### Architecture decision records

Detailed reasoning for the major architecture choices lives in [docs/adr/](docs/adr/).
