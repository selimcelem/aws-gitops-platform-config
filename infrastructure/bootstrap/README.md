# Bootstrap

This module creates the AWS resources that Terraform itself depends on for state management:

- An S3 bucket for the remote state file (versioned, encrypted, public access blocked).
- A DynamoDB table for state locking.

These resources have a different lifecycle from the rest of the platform. The platform under infrastructure/modules/ is destroyed at the end of every working session for cost reasons. The bootstrap stays up across sessions because it holds the state of the platform.

## Usage

This module is run with local state once. After it runs, the platform modules use S3 backend pointing at the bucket it created.

### First-time setup

```
cd infrastructure/bootstrap
terraform init
terraform apply
```

After apply, copy the output values into a local backend.hcl file at the root of the platform Terraform configuration. That file is gitignored.

### Tearing down (rare)

Only tear this down if you no longer want any state for the platform. Doing so will lose the state of any running infrastructure.

```
terraform destroy
```

## Outputs

- tfstate_bucket_name: name of the S3 bucket to use as the backend.
- tflock_table_name: name of the DynamoDB table to use for locking.
- aws_region: region the bucket and table live in.
