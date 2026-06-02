locals {
  name_prefix = "${var.project_name}-${var.environment}"

  services = ["api", "worker"]
}

# -----------------------------------------------------------------------------
# IRSA trust policies (one per service)
# -----------------------------------------------------------------------------
# Each ServiceAccount in Kubernetes maps to exactly one IAM role. The trust
# policy says "this role can be assumed via web identity from the cluster's
# OIDC provider, but only when the token's sub claim matches the right
# ServiceAccount in the right namespace."

data "aws_iam_policy_document" "irsa_trust" {
  for_each = toset(local.services)

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.service_namespace}:${each.value}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# -----------------------------------------------------------------------------
# IRSA roles (one per service)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "service" {
  for_each = toset(local.services)

  name               = "${local.name_prefix}-${each.value}"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust[each.value].json

  tags = merge(var.tags, {
    Name    = "${local.name_prefix}-${each.value}"
    Service = each.value
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Logs permissions (always attached to both roles)
# -----------------------------------------------------------------------------
# Every pod needs to be able to write logs. The container logs from EKS pods
# flow into CloudWatch via Fluent Bit (or the new EKS observability addon)
# under the /aws/eks/<cluster>/ log-group prefix.

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/${local.name_prefix}/*",
    ]
  }
}

resource "aws_iam_policy" "logs" {
  name        = "${local.name_prefix}-logs"
  description = "Allows writing logs to the cluster's CloudWatch log groups."
  policy      = data.aws_iam_policy_document.logs.json
}

resource "aws_iam_role_policy_attachment" "logs" {
  for_each = aws_iam_role.service

  role       = each.value.name
  policy_arn = aws_iam_policy.logs.arn
}

# -----------------------------------------------------------------------------
# SQS permissions (attached only when the SQS module is deployed)
# -----------------------------------------------------------------------------
# The API publishes jobs to the queue. The worker reads from the queue and
# deletes messages once they're processed. Different services need different
# SQS actions, so two distinct policies.

data "aws_iam_policy_document" "api_sqs_publish" {
  count = var.sqs_job_queue_arn != "" ? 1 : 0

  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
    ]
    resources = [var.sqs_job_queue_arn]
  }
}

resource "aws_iam_policy" "api_sqs_publish" {
  count = var.sqs_job_queue_arn != "" ? 1 : 0

  name        = "${local.name_prefix}-api-sqs-publish"
  description = "Allows the API service to publish messages to the job queue."
  policy      = data.aws_iam_policy_document.api_sqs_publish[0].json
}

resource "aws_iam_role_policy_attachment" "api_sqs_publish" {
  count = var.sqs_job_queue_arn != "" ? 1 : 0

  role       = aws_iam_role.service["api"].name
  policy_arn = aws_iam_policy.api_sqs_publish[0].arn
}

data "aws_iam_policy_document" "worker_sqs_consume" {
  count = var.sqs_job_queue_arn != "" ? 1 : 0

  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [var.sqs_job_queue_arn]
  }
}

resource "aws_iam_policy" "worker_sqs_consume" {
  count = var.sqs_job_queue_arn != "" ? 1 : 0

  name        = "${local.name_prefix}-worker-sqs-consume"
  description = "Allows the worker service to consume messages from the job queue."
  policy      = data.aws_iam_policy_document.worker_sqs_consume[0].json
}

resource "aws_iam_role_policy_attachment" "worker_sqs_consume" {
  count = var.sqs_job_queue_arn != "" ? 1 : 0

  role       = aws_iam_role.service["worker"].name
  policy_arn = aws_iam_policy.worker_sqs_consume[0].arn
}

# -----------------------------------------------------------------------------
# Database secret permissions (attached only when the RDS module is deployed)
# -----------------------------------------------------------------------------
# The worker reads the database connection string from Secrets Manager rather
# than environment variables, so credentials aren't baked into pod specs or
# Git history.

data "aws_iam_policy_document" "worker_db_secret" {
  count = var.db_secret_arn != "" ? 1 : 0

  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }
}

resource "aws_iam_policy" "worker_db_secret" {
  count = var.db_secret_arn != "" ? 1 : 0

  name        = "${local.name_prefix}-worker-db-secret"
  description = "Allows the worker service to read the database connection string from Secrets Manager."
  policy      = data.aws_iam_policy_document.worker_db_secret[0].json
}

resource "aws_iam_role_policy_attachment" "worker_db_secret" {
  count = var.db_secret_arn != "" ? 1 : 0

  role       = aws_iam_role.service["worker"].name
  policy_arn = aws_iam_policy.worker_db_secret[0].arn
}
