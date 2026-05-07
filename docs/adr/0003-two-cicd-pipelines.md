# ADR-0003: Two CI/CD pipelines separated by trigger

## Status

Accepted.

## Context

The app repo and config repo each have different change patterns and different consequences when changed. Application code changes should rebuild Docker images and update Kubernetes manifests, but should not run `terraform apply`. Infrastructure changes in the config repo should run `terraform apply`, but should not rebuild any images.

Two approaches were considered:

1. **One unified pipeline** in either repo that detects what changed and runs the relevant steps conditionally.
2. **Two separate pipelines**, each in its own repo, each with a focused trigger.

## Decision

Two separate pipelines.

- **App repo** has `build-and-push.yml`. Triggered on push to `main` when `services/**` or `Dockerfile` paths change. Builds the image, pushes to ECR, and bumps the image tag in the config repo to trigger ArgoCD sync.
- **Config repo** has `terraform.yml`. Triggered on push to `main` when `infrastructure/**` paths change. Runs `terraform plan` on pull requests and `terraform apply` on merge to main.

## Consequences

**Benefits:**

- A Terraform typo never rebuilds containers.
- A code change never runs `terraform apply`.
- Each pipeline file is short and focused, easy to read and debug.
- Failures in one pipeline never block the other.

**Costs:**

- Two pipelines to maintain instead of one.
- Cross-repo trigger (image tag bump) requires the app repo's CI to authenticate to the config repo, which is handled with a fine-scoped GitHub token or deploy key.

This pattern is consistent with how mature GitOps teams structure their CI.
