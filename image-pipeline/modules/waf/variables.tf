variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "rate_limit_per_5min" {
  type        = number
  description = "Max requests per 5 minutes per IP before blocking"
  default     = 2000
}
