# Architecture Decision Records

This folder contains records of major architecture decisions made during the design and build of this platform. Each ADR captures a single decision with its context, the alternatives considered, and the reasoning behind the choice.

## Format

Each ADR follows a lightweight format:

- **Status:** Proposed, Accepted, or Superseded.
- **Context:** What is the problem or question that needs deciding?
- **Decision:** What did I decide and why?
- **Consequences:** What does this choice cost or enable downstream?

## Index

- [ADR-0001: Two-repo split (app and config)](0001-two-repo-split.md)
- [ADR-0002: Self-install ArgoCD via Terraform helm_release](0002-argocd-self-install.md)
- [ADR-0003: Two CI/CD pipelines separated by trigger](0003-two-cicd-pipelines.md)
- [ADR-0004: Kustomize overlays for dev and prod in one config repo](0004-kustomize-overlays.md)
