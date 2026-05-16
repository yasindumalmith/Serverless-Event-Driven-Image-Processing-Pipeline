variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "max_receive_count" {
  type        = number
  description = "Number of failures before a message goes to the DLQ"
  default     = 3
}

variable "visibility_timeout_seconds" {
  type        = number
  description = "Seconds a message is hidden after being received"
  default     = 300
}
