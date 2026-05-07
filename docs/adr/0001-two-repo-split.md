# ADR-0001: Two-repo split (app and config)

## Status

Accepted.

## Context

GitOps requires a clean separation between the source of truth for application code and the source of truth for cluster state. ArgoCD watches a Git repository for declarative manifests and reconciles the cluster against them. If application source and Kubernetes manifests live in the same repo, every code change triggers ArgoCD to re-evaluate the entire cluster, and access control becomes harder to reason about.

Three repository structures were considered:

1. **One repo** containing app code, Dockerfiles, manifests, and Terraform.
2. **Two repos**: one for app code and CI, one for Kubernetes manifests and infrastructure.
3. **Three repos**: one for app code, one for dev manifests, one for prod manifests.

## Decision

Two repos: `aws-gitops-platform-app` and `aws-gitops-platform-config`.

The app repo holds application source, Dockerfiles, and the CI workflow that builds images and pushes to ECR. The config repo holds Kubernetes manifests, Helm charts, Kustomize overlays, ArgoCD application definitions, and Terraform infrastructure code. ArgoCD watches the config repo only.

## Consequences

**Benefits:**

- Clean separation between what gets built and what runs in the cluster.
- ArgoCD only reconciles when manifests change, not when code changes.
- Access control can differ per repo if needed.
- Mirrors the pattern used by most GitOps-mature teams.

**Costs:**

- Cross-repo coordination is required: the app repo's CI pipeline must commit an image tag update to the config repo to trigger a deploy.
- Two repos to maintain instead of one.

The three-repo split (separating prod manifests into their own repo for stricter access control) was rejected for this project as adding complexity without portfolio benefit at this stage. It can be revisited if the project grows.
