# ADR-0009: ECR repositories with immutable tags and lifecycle policy

## Status

Accepted.

## Context

The platform needs a container registry that container images are pushed to during CI and pulled from when pods start. Several design choices have real consequences:

1. One shared repository or one repository per service?
2. Mutable or immutable image tags?
3. Should image scanning be on or off?
4. How should old images be handled to control storage cost?

## Decision

Create one ECR repository per service (`gitops-platform-dev-api`, `gitops-platform-dev-worker`). Configure each repository with `IMMUTABLE` tag mutability, scan-on-push enabled, AES-256 encryption at rest, and a lifecycle policy that retains the 10 most recent images and expires older ones.

## Consequences

**Benefits of one repository per service:**

- Permissions can be scoped per service. A future CI job that builds the API image can have IAM permissions to push to only the API repository, not the worker repository. This is meaningful least-privilege isolation.
- Lifecycle policies, tags, and scan results are per-service, so noisy churn in one service does not push useful images out of another.
- Repository names are self-documenting in the AWS console and in image URIs.

**Benefits of immutable tags:**

- This is the most important decision in this module. With immutable tags, a tag like `v1.2.3` or a SHA-tagged image can be pushed exactly once. Subsequent pushes of the same tag fail.
- The GitOps workflow depends on this. The config repo references images by tag, and ArgoCD syncs whatever the manifests say. If tags were mutable, someone could silently change what `v1.0.0` points to without a Git commit, breaking the audit trail that GitOps is built on.
- Rollbacks become trivially safe: pointing the manifest back to an older tag always pulls the same bytes that ran before.

**Cost of immutable tags:**

- Pipelines cannot use a moving "latest" pointer. Every CI build must tag with a unique value, typically the Git commit SHA. This is more disciplined but slightly more work to set up.

**Benefits of scan-on-push:**

- Every uploaded image is automatically scanned against the AWS-maintained CVE database. Vulnerabilities surface in the AWS console and via the AWS API without needing a separate scanning pipeline.
- Free at this scale.

**Benefits of the lifecycle policy:**

- Without a lifecycle policy, every CI build accumulates in the repository indefinitely. Storage is cheap ($0.10 per GB-month) but image lists become unwieldy and old, vulnerable images stay accessible for accidental rollback to.
- Retaining 10 images is enough for several rollbacks while keeping the repository clean.
