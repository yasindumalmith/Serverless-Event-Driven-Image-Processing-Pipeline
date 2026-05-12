# Placeholders — we'll add real outputs as we build each module
output "environment" {
  value = var.environment
}

output "region" {
  value = var.aws_region
}

output "iam_role_arns" {
  description = "All Lambda IAM role ARNs"
  value       = module.iam.all_role_arns
}
