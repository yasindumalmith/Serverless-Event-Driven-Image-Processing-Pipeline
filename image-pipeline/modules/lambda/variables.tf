variable "project" {
  type        = string
  description = "Project name prefix"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "upload_bucket_name" {
  type        = string
  description = "Name of the upload S3 bucket"
}

variable "processed_bucket_name" {
  type        = string
  description = "Name of the processed S3 bucket"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name of the metadata DynamoDB table"
}

variable "presign_role_arn" {
  type        = string
  description = "IAM role ARN for the presign Lambda"
}

variable "status_role_arn" {
  type        = string
  description = "IAM role ARN for the status Lambda"
}
