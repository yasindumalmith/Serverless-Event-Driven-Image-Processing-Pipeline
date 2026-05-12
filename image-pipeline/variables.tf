variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project" {
  description = "Project name — used as prefix for resource names"
  type        = string
  default     = "img-pipeline"
}

variable "owner" {
  description = "Owner tag for resources (your name or team)"
  type        = string
  default     = "student"
}

variable "notification_email" {
  description = "Email for processing notifications"
  type        = string
}
