# Build Log

## 2026-05-06

**What:** I initialized the platform configuration repository. I scaffolded the directory tree for Terraform modules (VPC, EKS, ECR, RDS, SQS, IAM, ArgoCD), Helm charts for the API and worker services, Kustomize base and overlays (dev, prod), ArgoCD application manifests, and observability configuration for Prometheus and Grafana.

**Why:** This repo will be the single source of truth for everything ArgoCD reconciles. Laying out the directory structure first surfaces design questions about module boundaries, chart layout, and overlay strategy before any code is committed.

**Result:** Config repo scaffolded locally and pushed. Companion app repo scaffolded and pushed in parallel.

## 2026-05-07

**What:** I reviewed the planned architecture against current AWS capabilities and finalised key design decisions. Updated the README with sections covering ArgoCD installation choice and the two-pipeline CI/CD pattern. Created `docs/adr/` with four Architecture Decision Records covering the two-repo split, ArgoCD self-install vs the AWS-managed EKS Capability launched in November 2025, the two-pipeline CI/CD design, and the Kustomize overlay layout.

**Why:** Capturing decisions in ADRs while the reasoning is fresh makes the architecture defensible later. The README updates surface the most important architecture choices on the front page so a reader does not need to dig.

**Result:** README updated with three new sections. Four ADRs and an index README created under `docs/adr/`. All major architecture decisions documented before any infrastructure code is written.
