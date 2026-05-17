variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "ops_alerts_topic_arn" {
  type = string
}

variable "lambda_function_names" {
  type = map(string)
}

variable "sqs_queue_names" {
  type = map(string)
}

variable "sqs_dlq_names" {
  type = map(string)
}

variable "dynamodb_table_name" {
  type = string
}

variable "api_gateway_name" {
  type = string
}
