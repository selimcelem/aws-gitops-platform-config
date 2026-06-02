# ADR-0007: Least-privilege IAM via IRSA with deferred resource wiring

## Status

Accepted.

## Context

The platform's pods need AWS access for two concrete reasons: the API service publishes job messages to SQS, and the worker service consumes those messages and reads database credentials from Secrets Manager. Both services also need to write logs to CloudWatch.

There are three common ways to give Kubernetes pods AWS credentials:

1. **Static credentials in environment variables or files.** Long-lived access keys baked into pod specs or Kubernetes Secrets. Operationally simple but creates a permanent credential leak risk.
2. **Node-level IAM role.** All pods on a given node share the node's IAM permissions via the EC2 instance metadata service. No per-pod isolation; a compromised pod has the same AWS access as every other pod on the node.
3. **IRSA (IAM Roles for Service Accounts).** Each Kubernetes ServiceAccount maps to a distinct IAM role via the cluster's OIDC provider. AWS issues short-lived credentials per pod, scoped to that pod's role.

A second question: at the time of writing this module, the SQS queue and RDS database secret do not yet exist. The IAM module needs to be deployable on its own without dangling references, but the policies that reference those resources also need to be in code, not added manually later.

## Decision

Use IRSA. Create one IAM role per service (`gitops-platform-dev-api`, `gitops-platform-dev-worker`). Each role's trust policy is scoped to a specific Kubernetes ServiceAccount in a specific namespace via the OIDC provider's `sub` and `aud` claims. Permission policies are scoped to exact resource ARNs.

For policies that reference resources from modules that do not yet exist (SQS, RDS), use Terraform's `count = var.x != "" ? 1 : 0` pattern. The input variables default to empty strings, so today the conditional policies are not created. When the SQS and RDS modules are deployed and their ARNs are passed through, the policies activate automatically on the next apply.

## Consequences

**Benefits:**

- Each pod has its own credentials. If the API service is compromised, the attacker can publish to one SQS queue. They cannot drain queues, read database secrets, or pivot to other AWS resources.
- The CloudWatch Logs policy is scoped to `arn:aws:logs:eu-west-1:ACCOUNT:log-group:/aws/eks/gitops-platform-dev/*`, not the entire account's log groups.
- The trust policy's `sub` condition (`system:serviceaccount:default:api`) means no other ServiceAccount in the cluster can assume the role, even if its annotation pointed at the right ARN. This is true even across namespaces.
- The IAM module is deployable today as a self-contained unit. The conditional pattern makes the future-resource policies explicit in code rather than relying on a TODO comment to remember them later.
- When the SQS and RDS modules come online, the only change to this module is the root configuration passing the new ARNs through. The module itself does not change.

**Costs:**

- IRSA requires that the EKS cluster's OIDC provider be registered with IAM, which adds one resource to the EKS module. We already did this in ADR-0006's predecessor work.
- The `count` pattern complicates the resources slightly: every conditional policy and attachment is indexed (`aws_iam_policy.api_sqs_publish[0]` rather than just `aws_iam_policy.api_sqs_publish`). This is readable in code but means anyone consuming module outputs needs to be aware of the conditional indexing.
- A pod whose ServiceAccount is not annotated with `eks.amazonaws.com/role-arn` cannot use IRSA. This is a deployment-time concern that lives in the Helm charts, not in the IAM module. The IAM module is correct on its own; the Helm chart must reference the right role ARN.
