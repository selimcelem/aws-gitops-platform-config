output "repository_urls" {
  description = "Map of service name to ECR repository URL."
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of service name to ECR repository ARN."
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}

output "repository_names" {
  description = "Map of service name to ECR repository name."
  value       = { for k, v in aws_ecr_repository.this : k => v.name }
}

output "registry_id" {
  description = "AWS account ID hosting the registry. The same for all repositories in the same account."
  value       = values(aws_ecr_repository.this)[0].registry_id
}
