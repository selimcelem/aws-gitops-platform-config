# ADR-0002: Self-install ArgoCD via Terraform helm_release

## Status

Accepted.

## Context

ArgoCD can be installed onto an EKS cluster three ways:

1. **Manual install** via `helm install` after `terraform apply` provisions the cluster.
2. **Self-install via Terraform** using the `helm_release` resource so ArgoCD comes up as part of `terraform apply`.
3. **AWS-managed EKS Capability for ArgoCD**, launched in November 2025, where AWS runs ArgoCD in their control plane and handles patching, scaling, and upgrades.

The managed capability is attractive for production teams: AWS owns the SLA, patching is automatic, and the operational burden of running a critical GitOps controller is offloaded. ArgoCD is core infrastructure (if it breaks, no deploys can happen), so reducing operational risk is genuinely valuable.

## Decision

Self-install via Terraform `helm_release`.

## Consequences

**Benefits:**

- The entire platform comes up reproducibly from a single `terraform apply`. No post-cluster manual install step.
- Demonstrates hands-on platform engineering work for portfolio review.
- Avoids the per-hour cost of the managed capability.
- Avoids the AWS Identity Center setup the managed capability requires.
- Full control over ArgoCD version, configuration, and Helm values.

**Costs:**

- I am responsible for upgrades and patching.
- If ArgoCD has a bug or misconfiguration, I am the one debugging it.
- For a production team with no dedicated platform engineers, the managed capability would likely be the better trade-off (less operational overhead, AWS owns the SLA).

If this were a real production system at a small company without platform staff, I would reconsider and likely choose the managed capability.
