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

## 2026-05-07 (later)

**What:** I applied the VPC module to AWS, verified the deployment in the console, and captured screenshots as portfolio evidence. Screenshots cover the VPC list and details, the resource map showing the visual topology, all six subnets with their CIDRs, the route tables, and the NAT Gateway with its Elastic IP attached. Screenshots committed under `docs/screenshots/vpc/` and embedded in the VPC module README.

**Why:** Visual proof that the Terraform code produced what was intended is central to a portfolio piece. A reviewer scrolling through the repo can see the module code, then see the actual AWS resources it created, without needing access to my AWS account. Account IDs were redacted from screenshots before committing.

**Result:** 18 resources created via `terraform apply`. State stored in S3, locked via S3-native lockfile. VPC running with three public and three private subnets across eu-west-1a/b/c, single NAT Gateway in eu-west-1a, Internet Gateway attached. Five screenshots captured and referenced from the module README.

## 2026-05-07 (session end)

**What:** I ran `terraform destroy` against the platform configuration to tear down the VPC and all associated resources.

**Why:** Cost discipline. The platform is destroyed at the end of every working session so I am never billed for idle infrastructure. The bootstrap (S3 state bucket) stays alive across sessions because it holds the state of the platform; the platform itself is recreated cleanly from `terraform apply` next session.

**Result:** 18 resources destroyed in approximately 1 minute 10 seconds. NAT Gateway dominated the destroy time as expected. State file in S3 is now effectively empty (319 bytes of metadata, no resources). All AWS costs for this session have stopped. Total session cost: a few cents (NAT Gateway ran for roughly 35 minutes).

## 2026-05-12

**What:** I added the EKS module to the platform Terraform and brought up an EKS cluster end-to-end. The module provisions the cluster control plane, a managed node group of two t3.medium on-demand instances, the IAM roles for both, an OIDC provider for IRSA, and an explicit access entry granting my IAM user cluster-admin via the `AmazonEKSClusterAdminPolicy`. The cluster is in `EKS API and ConfigMap` authentication mode with `bootstrap_cluster_creator_admin_permissions = false`, so all admin grants are declared in code rather than implicit.

**Why:** EKS is the compute foundation the rest of the platform sits on. Every other Kubernetes-native component (ArgoCD, Prometheus, Grafana, the API and worker services) runs as pods on this cluster. Going with explicit access entries instead of the bootstrap permission flag means every cluster-admin grant is visible in Terraform, auditable in git history, and reproducible across cluster recreations.

**Result:** Cluster `gitops-platform-dev` running Kubernetes 1.31 with two Ready nodes. Verified end-to-end with `kubectl get nodes`, `kubectl get pods --all-namespaces` (aws-node, coredns, kube-proxy all Running across both nodes), and `kubectl cluster-info`. OIDC provider registered so IRSA will work for pod-level AWS access later. Five screenshots captured under `docs/screenshots/eks/` and referenced from the module README. Two pinned providers (`hashicorp/aws ~> 5.0`, `hashicorp/tls ~> 4.0`) now used by the root configuration.

## 2026-05-12 (session end)

**What:** I ran `terraform destroy` to tear down the platform infrastructure (VPC, EKS cluster, node group, IAM roles, OIDC provider, access entries) after verifying the EKS module worked end-to-end.

**Why:** Cost discipline. EKS is the largest cost contributor in this project (control plane plus EC2 nodes), so destroying at session end is non-negotiable. The bootstrap S3 bucket stays alive because it holds the platform state; the platform itself is recreated cleanly from `terraform apply` next session.

**Result:** 29 resources destroyed. All AWS costs for this session have stopped. Total session cost: roughly 60-70 cents (NAT for ~2 hours, EKS control plane and two t3.medium nodes for ~50 minutes, including the destroy-and-recreate cycle when switching `bootstrap_cluster_creator_admin_permissions` from true to false).

## 2026-06-02 (ECR module)

**What:** I added the ECR module to the platform Terraform and brought up two container repositories: `gitops-platform-dev-api` and `gitops-platform-dev-worker`. Each repository is configured with immutable tags, scan-on-push, AES-256 encryption, and a lifecycle policy that retains the 10 most recent images and expires the rest.

**Why:** ECR is the source-of-truth registry that links the app repo's CI pipeline to the cluster's running images. Immutable tags are non-negotiable for a GitOps workflow: the config repo references images by tag, and a mutable tag would let someone silently swap what `v1.0.0` points to without a Git commit, breaking the audit trail that GitOps depends on.

**Result:** Two repositories live in eu-west-1, both with immutable tags and scan-on-push enabled. Lifecycle policies attached. Three screenshots committed under `docs/screenshots/ecr/`. Module is generic enough to add a third service later by appending to the `service_names` list in the root configuration.

## 2026-06-02 (IAM module)

**What:** I added the IAM module that creates IRSA (IAM Roles for Service Accounts) roles for the API and worker services. Each role has a trust policy scoped to its specific Kubernetes ServiceAccount via the cluster's OIDC provider, plus a least-privilege CloudWatch Logs policy attached today. SQS and Secrets Manager policies are wired as conditional resources that activate when the SQS and RDS modules come online.

**Why:** IRSA is how pods get AWS credentials in a production-grade EKS setup. The alternative (injecting access keys via environment variables, or letting every pod use the node's IAM role) either creates long-lived credential risk or violates least privilege. IRSA gives each pod its own short-lived, scoped credentials via web identity tokens, with no static keys anywhere in the cluster.

**Result:** Two roles live in IAM: `gitops-platform-dev-api` and `gitops-platform-dev-worker`. Trust policies correctly pin to `system:serviceaccount:default:<service>` so only the matching ServiceAccount can assume the role. CloudWatch Logs policy is scoped to log groups under `/aws/eks/gitops-platform-dev/*`, not the entire account. Three screenshots committed under `docs/screenshots/iam/`. The `count = var.x != "" ? 1 : 0` pattern keeps SQS and Secrets Manager policies dormant today and ready to attach automatically when downstream modules exist.

## 2026-06-02 (session end)

**What:** I ran `terraform destroy` to tear down the platform infrastructure after verifying the ECR and IAM modules. The destroy covered the VPC, EKS cluster, node group, OIDC provider, EKS access entries, both ECR repositories with their lifecycle policies, and both IRSA roles with their CloudWatch Logs policy attachments.

**Why:** Cost discipline. EKS is the largest cost contributor and runs only when there is active work to do. The S3 state bucket persists, so the next session's `terraform apply` will recreate the same 38 resources from the same code.

**Result:** 38 resources destroyed. Verified that no Elastic IPs remain orphaned (which would otherwise accrue $0.005/hr). Total session cost: roughly 50-60 cents (VPC NAT for around 2 hours, EKS control plane plus two t3.medium nodes for around 90 minutes).
