locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_cognito_user_pool" "main" {
  name = "${local.name_prefix}-user-pool"

  # ── Username configuration ──────────────────────────────────────────────────
  # Users sign in with their email address (not a separate username)
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # ── Password policy ─────────────────────────────────────────────────────────
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  # ── MFA — optional for users to enable ──────────────────────────────────────
  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  # ── Account recovery — email only ───────────────────────────────────────────
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # ── Email verification settings ─────────────────────────────────────────────
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Verify your email for ${var.project}"
    email_message        = "Your verification code is {####}"
  }

  # ── Email sending — use Cognito's free default (50 emails/day) ──────────────
  # In production, switch to SES for unlimited and customisation
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # ── Standard attributes users can have ──────────────────────────────────────
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 100
    }
  }

  # ── Deletion protection in prod ─────────────────────────────────────────────
  deletion_protection = var.environment == "prod" ? "ACTIVE" : "INACTIVE"

  tags = {
    Name = "${local.name_prefix}-user-pool"
  }
}
