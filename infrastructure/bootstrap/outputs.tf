output "tfstate_bucket_name" {
  description = "Name of the S3 bucket holding Terraform state."
  value       = aws_s3_bucket.tfstate.id
}

output "tfstate_bucket_arn" {
  description = "ARN of the S3 bucket holding Terraform state."
  value       = aws_s3_bucket.tfstate.arn
}

output "aws_region" {
  description = "AWS region the bootstrap resources live in."
  value       = var.aws_region
}
