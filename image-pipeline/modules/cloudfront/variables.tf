variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "processed_bucket_id" {
  type        = string
  description = "ID of the processed S3 bucket"
}

variable "processed_bucket_arn" {
  type        = string
  description = "ARN of the processed S3 bucket"
}

variable "processed_bucket_domain" {
  type        = string
  description = "Regional domain name of the processed S3 bucket"
}

variable "waf_web_acl_arn" {
  type        = string
  description = "ARN of the WAF WebACL to attach (optional)"
  default     = null
}

variable "price_class" {
  type        = string
  description = "CloudFront price class: PriceClass_All, PriceClass_200, or PriceClass_100"
  default     = "PriceClass_100"
}
