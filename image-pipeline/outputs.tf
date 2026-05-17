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

output "upload_bucket_name" {
  description = "Upload bucket name — you'll need this for the frontend"
  value       = module.s3.upload_bucket_name
}

output "processed_bucket_name" {
  description = "Processed bucket name"
  value       = module.s3.processed_bucket_name
}

output "dynamodb_table_name" {
  description = "DynamoDB metadata table name"
  value       = module.dynamodb.table_name
}


output "cognito_user_pool_id" {
  description = "Cognito User Pool ID (for frontend config)"
  value       = module.cognito.user_pool_id
}

output "cognito_app_client_id" {
  description = "Cognito App Client ID (for frontend config)"
  value       = module.cognito.app_client_id
}

output "cognito_hosted_ui" {
  description = "Cognito hosted login URL"
  value       = module.cognito.hosted_ui_login_url
}

output "api_endpoint" {
  description = "Base URL of the API"
  value       = module.api_gateway.api_endpoint
}


output "sqs_queue_urls" {
  description = "URLs of the processing queues"
  value       = module.sqs.queue_urls
}

output "sqs_dlq_urls" {
  description = "URLs of the dead letter queues"
  value       = module.sqs.dlq_urls
}


output "cloudfront_domain" {
  description = "CloudFront domain for accessing processed images"
  value       = module.cloudfront.domain_name
}

output "cloudfront_url_example" {
  description = "Example URL format for accessing a processed image"
  value       = "https://${module.cloudfront.domain_name}/processed/{userId}/{imageId}/medium.jpg"
}
