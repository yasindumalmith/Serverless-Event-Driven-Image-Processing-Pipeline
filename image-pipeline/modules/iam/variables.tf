variable "project" {
  type        = string
  description = "Project name prefix"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/prod)"
}

variable "upload_bucket_arn" {
  type        = string
  description = "ARN of the upload S3 bucket"
  # Default placeholder until S3 module is built
  default = "arn:aws:s3:::placeholder-upload-bucket"
}

variable "processed_bucket_arn" {
  type        = string
  description = "ARN of the processed S3 bucket"
  default     = "arn:aws:s3:::placeholder-processed-bucket"
}

variable "dynamodb_table_arn" {
  type        = string
  description = "ARN of the metadata DynamoDB table"
  default     = "arn:aws:dynamodb:us-east-1:000000000000:table/placeholder"
}

variable "sqs_queue_arn" {
  type        = string
  description = "ARN of the processing SQS queue"
  default     = "arn:aws:sqs:us-east-1:000000000000:placeholder"
}

variable "sqs_dlq_arn" {
  type        = string
  description = "ARN of the dead-letter queue"
  default     = "arn:aws:sqs:us-east-1:000000000000:placeholder-dlq"
}

variable "sns_topic_arn" {
  type        = string
  description = "ARN of the notification SNS topic"
  default     = "arn:aws:sns:us-east-1:000000000000:placeholder"
}
