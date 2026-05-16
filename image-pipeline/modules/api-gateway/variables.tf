variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "cognito_user_pool_id" {
  type        = string
  description = "Cognito User Pool ID for JWT verification"
}

variable "cognito_app_client_id" {
  type        = string
  description = "Cognito App Client ID (JWT audience)"
}

variable "presign_function_name" {
  type = string
}

variable "presign_invoke_arn" {
  type = string
}

variable "status_function_name" {
  type = string
}

variable "status_invoke_arn" {
  type = string
}

variable "aws_region" {
  type = string
}
