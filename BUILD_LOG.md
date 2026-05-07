# Build Log

## 2026-05-06

**What:** I initialized the platform configuration repository. I scaffolded the directory tree for Terraform modules (VPC, EKS, ECR, RDS, SQS, IAM, ArgoCD), Helm charts for the API and worker services, Kustomize base and overlays (dev, prod), ArgoCD application manifests, and observability configuration for Prometheus and Grafana.

**Why:** This repo will be the single source of truth for everything ArgoCD reconciles. Laying out the directory structure first surfaces design questions about module boundaries, chart layout, and overlay strategy before any code is committed.

**Result:** Config repo scaffolded locally and pushed. Companion app repo scaffolded and pushed in parallel.

## 2026-05-07

**What:** I reviewed the planned architecture against current AWS capabilities and finalised key design decisions. Updated the README with sections covering ArgoCD installation choice and the two-pipeline CI/CD pattern. Created `docs/adr/` with four Architecture Decision Records covering the two-repo split, ArgoCD self-install vs the AWS-managed EKS Capability launched in November 2025, the two-pipeline CI/CD design, and the Kustomize overlay layout.

**Why:** Capturing decisions in ADRs while the reasoning is fresh makes the architecture defensible later. The README updates surface the most important architecture choices on the front page so a reader does not need to dig.

**Result:** README updated with three new sections. Four ADRs and an index README created under `docs/adr/`. All major architecture decisions documented before any infrastructure code is written.

## 2026-05-07 (later)

**What:** I created the Terraform bootstrap module under `infrastructure/bootstrap/` and applied it to AWS. The module provisions an S3 bucket for remote Terraform state (versioned, AES256-encrypted, public access blocked, 30-day lifecycle on old versions) and a DynamoDB table for state locking. The S3 bucket name uses a random hex suffix to avoid embedding identifying information.

**Why:** Remote state with locking is the industry standard for any non-trivial Terraform project. State in S3 is durable and shareable across machines and CI runners. The DynamoDB lock prevents two `terraform apply` runs from corrupting state by writing concurrently. The bootstrap is intentionally separate from the platform modules: the bootstrap stays up across sessions because it holds the state, while the platform itself is destroyed at the end of every session for cost reasons.

**Result:** S3 bucket and DynamoDB table created in `eu-west-1`. Bootstrap state lives locally for now (chicken-and-egg: the backend resources cannot store their own state remotely). The platform Terraform under `infrastructure/modules/` will use this S3 backend, configured at init time via a local `backend.hcl` that is gitignored. `.gitignore` updated to exclude `backend.hcl` and `.terraform/` directories. Bootstrap source committed and pushed.

## 2026-05-07 (later)

**What:** I migrated the Terraform state locking mechanism from a DynamoDB table to S3-native locking (`use_lockfile = true`). Removed the DynamoDB resource from the bootstrap module, applied to destroy the table, updated the local `backend.hcl`, and re-initialised the platform Terraform with the new backend config.

**Why:** During the first init of the platform Terraform, the AWS provider emitted a deprecation warning for the `dynamodb_table` backend parameter. Newer Terraform (1.10+) and AWS provider (5.x) versions support locking the state directly via an object in the S3 bucket, eliminating the need for a separate DynamoDB table. Since no platform state existed yet, this was the right moment to switch to the current recommended pattern.

**Result:** DynamoDB lock table destroyed. Bootstrap module simplified to S3-only. Backend config now uses `use_lockfile = true`. Deprecation warning gone. ADR-0005 records the decision.
