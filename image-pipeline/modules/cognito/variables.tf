variable "project" {
  type        = string
  description = "Project name prefix"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/prod)"
}

variable "callback_urls" {
  type        = list(string)
  description = "Allowed callback URLs after Cognito login"
  default     = ["http://localhost:3000/callback"]
}

variable "logout_urls" {
  type        = list(string)
  description = "Allowed logout redirect URLs"
  default     = ["http://localhost:3000/logout"]
}
