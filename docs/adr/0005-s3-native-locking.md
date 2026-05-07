# ADR-0005: S3-native state locking instead of DynamoDB

## Status

Accepted.

## Context

Terraform state must be locked during `apply` and `destroy` to prevent concurrent runs from corrupting the state file. Two mechanisms are available when using the S3 backend:

1. **External DynamoDB table** (the long-standing pattern). A `LockID` attribute is written to a DynamoDB table for the duration of the operation. The Terraform S3 backend supports this via the `dynamodb_table` parameter.

2. **S3-native lockfile**. Starting with the AWS provider 5.x and Terraform 1.10+, the S3 backend supports storing the lock as an object in the same bucket as the state. Enabled via `use_lockfile = true`. The DynamoDB-based parameter is deprecated and emits a warning on every command.

## Decision

Use S3-native lockfile (`use_lockfile = true`).

## Consequences

**Benefits:**

- One fewer AWS resource to provision, manage, and pay for. DynamoDB on-demand pricing was already negligible, but eliminating the resource entirely is cleaner.
- The deprecation warning is gone. The bootstrap and `backend.hcl` reflect the current recommended pattern.
- Locking lives in the same bucket as the state, so a single resource controls both.

**Costs:**

- Older Terraform versions (pre-1.10) cannot use this mechanism. We are on 1.15.x, so this is not a constraint, but if future contributors run an older version locally they would need to upgrade.
- Tooling and tutorials written before late 2024 still teach the DynamoDB pattern, so a reader unfamiliar with the change may be momentarily confused.

This decision was made during initial bootstrap before any platform state existed, so no migration was needed. The DynamoDB table created by the original bootstrap was destroyed cleanly.
