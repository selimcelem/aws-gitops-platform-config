output "service_role_arns" {
  description = "Map of service name to IAM role ARN. Used by Helm charts to annotate ServiceAccounts with eks.amazonaws.com/role-arn."
  value       = { for k, v in aws_iam_role.service : k => v.arn }
}

output "service_role_names" {
  description = "Map of service name to IAM role name."
  value       = { for k, v in aws_iam_role.service : k => v.name }
}

output "api_role_arn" {
  description = "ARN of the IAM role for the API service. Use this in the api ServiceAccount annotation."
  value       = aws_iam_role.service["api"].arn
}

output "worker_role_arn" {
  description = "ARN of the IAM role for the worker service. Use this in the worker ServiceAccount annotation."
  value       = aws_iam_role.service["worker"].arn
}
