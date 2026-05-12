variable "project" {
  type        = string
  description = "Project name prefix"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/prod)"
}

variable "suffix" {
  type        = string
  description = "Random suffix for globally unique bucket names"
}
