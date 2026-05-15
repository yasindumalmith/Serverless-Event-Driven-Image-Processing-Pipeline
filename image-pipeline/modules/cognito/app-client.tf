resource "aws_cognito_user_pool_client" "main" {
  name         = "${local.name_prefix}-app-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # ── No client secret — this is a public client (browser/mobile) ─────────────
  generate_secret = false

  # ── Authentication flows the client can use ─────────────────────────────────
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",      # Secure Remote Password — recommended
    "ALLOW_REFRESH_TOKEN_AUTH", # Allow token refresh
    "ALLOW_USER_PASSWORD_AUTH", # Username + password (used for testing)
  ]

  # ── Token expiration ────────────────────────────────────────────────────────
  id_token_validity      = 1  # 1 hour
  access_token_validity  = 1  # 1 hour
  refresh_token_validity = 30 # 30 days

  token_validity_units {
    id_token      = "hours"
    access_token  = "hours"
    refresh_token = "days"
  }

  # ── OAuth flows — for the hosted UI (login page provided by Cognito) ────────
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  supported_identity_providers = ["COGNITO"]

  # ── Prevent token reuse after sign-out ──────────────────────────────────────
  enable_token_revocation = true

  # ── Read/write permissions for the client ───────────────────────────────────
  read_attributes  = ["email", "email_verified", "name"]
  write_attributes = ["email", "name"]
}
