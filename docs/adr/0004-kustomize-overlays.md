# ADR-0004: Kustomize overlays for dev and prod in one config repo

## Status

Accepted.

## Context

Kustomize supports environment-specific configuration through a `base/` plus `overlays/` pattern. Two layouts were considered:

1. **Single config repo** with `overlays/dev/` and `overlays/prod/` side by side. This is the pattern shown in the official Kustomize documentation.
2. **Separate config repos** for dev and prod manifests, with stricter access control on the prod repo.

The separate-repo approach is the more mature production pattern. It allows different access controls, different review processes, and different ArgoCD instances per environment, which matters in regulated or high-risk environments.

## Decision

Single config repo with `overlays/dev/` and `overlays/prod/` inside it.

## Consequences

**Benefits:**

- Both overlays are visible in one place, making the multi-environment Kustomize pattern easy to read and review.
- Simpler CI wiring: one repo to authenticate to from the app repo.
- Matches the introductory pattern in the official Kustomize docs, so the structure is recognizable to anyone familiar with Kustomize.

**Costs:**

- No access-control separation between dev and prod manifests. A misdirected change in this repo could land in either overlay.
- For a production team with strict change-control requirements, the separate-repo split would be more appropriate.

Both overlays will be applied to a real cluster during the build (not at the same time, due to the cost rule that destroys infrastructure after each session). Screenshots of each environment running will be committed as portfolio evidence. The `prod` overlay is therefore not theoretical, it is exercised against the cluster, just not simultaneously with `dev`.
