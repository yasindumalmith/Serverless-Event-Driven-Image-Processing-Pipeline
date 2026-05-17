variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "notification_email" {
  type        = string
  description = "Email to receive failure alerts and admin notifications"
}
