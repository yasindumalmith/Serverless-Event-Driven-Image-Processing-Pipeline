output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN (used by API Gateway authorizer)"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Cognito User Pool endpoint URL"
  value       = aws_cognito_user_pool.main.endpoint
}

output "app_client_id" {
  description = "Cognito App Client ID (used by frontend)"
  value       = aws_cognito_user_pool_client.main.id
}

output "hosted_ui_domain" {
  description = "Cognito hosted UI domain"
  value       = "${aws_cognito_user_pool_domain.main.domain}.auth.us-east-1.amazoncognito.com"
}

output "hosted_ui_login_url" {
  description = "Direct URL to the hosted login page"
  value = format(
    "https://%s.auth.us-east-1.amazoncognito.com/login?client_id=%s&response_type=code&scope=email+openid+profile&redirect_uri=%s",
    aws_cognito_user_pool_domain.main.domain,
    aws_cognito_user_pool_client.main.id,
    var.callback_urls[0]
  )
}
