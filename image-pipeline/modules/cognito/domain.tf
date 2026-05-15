resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project}-${var.environment}-${random_id.domain_suffix.hex}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# Random suffix because Cognito domain names must be globally unique
resource "random_id" "domain_suffix" {
  byte_length = 3
}
