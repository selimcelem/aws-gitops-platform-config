# ADR-0006: Explicit EKS access entries instead of bootstrap admin permissions

## Status

Accepted.

## Context

When creating an EKS cluster, two mechanisms can grant the first cluster-admin credential:

1. `bootstrap_cluster_creator_admin_permissions = true` on the cluster resource. AWS automatically creates an access entry granting cluster-admin to whichever IAM principal ran `terraform apply`. The grant is implicit and tied to the creator identity.

2. `bootstrap_cluster_creator_admin_permissions = false` combined with explicit `aws_eks_access_entry` and `aws_eks_access_policy_association` resources. Every cluster-admin grant is declared in Terraform code, scoped to a named IAM principal, and uses the EKS-specific cluster-access-policy ARN namespace (for example `arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy`).

The cluster also requires an authentication mode. Three options exist: `CONFIG_MAP` (legacy `aws-auth` ConfigMap only), `API` (access entries only), and `API_AND_CONFIG_MAP` (both).

## Decision

Use `bootstrap_cluster_creator_admin_permissions = false` with an explicit `aws_eks_access_entry` and `aws_eks_access_policy_association` for the admin principal. Use authentication mode `API_AND_CONFIG_MAP`.

## Consequences

**Benefits:**

- Every cluster-admin grant is visible in Terraform code, auditable in git history, and reviewable in a pull request. There is no implicit access derived from "who happened to run apply."
- The cluster can be recreated cleanly and the access grants come back without re-running an apply from a specific identity.
- `API_AND_CONFIG_MAP` keeps the legacy `aws-auth` ConfigMap available as a fallback for any tooling that still expects it, while the access entries API is the path used for all new grants.
- If admin access needs to be granted to a new IAM principal, it is a code change followed by `terraform apply`, not a manual console action.

**Costs:**

- Required learning the EKS-specific policy ARN format. The standard IAM managed-policy ARN (`arn:aws:iam::aws:policy/...`) does not work for access policy associations. The EKS namespace ARN (`arn:aws:eks::aws:cluster-access-policy/...`) is required, and a wrong ARN returns an InvalidParameterException at apply time.
- The bootstrap-then-flip-to-false path is not viable because the bootstrap flag is immutable on a live cluster. Setting `bootstrap = false` after the cluster exists triggers a cluster replacement. The decision must be made at cluster creation.

This was discovered the hard way during the first attempt: starting with `bootstrap = true` and trying to add an explicit access entry produced a `ResourceInUseException` (AWS already created an access entry for the creator, so the Terraform-managed one collided). Flipping the flag to `false` then forced cluster replacement. Going forward, the module ships with `bootstrap = false` so the explicit access entry creates cleanly from the first apply.
