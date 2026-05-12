output "table_name" {
  description = "Name of the image metadata table"
  value       = aws_dynamodb_table.image_metadata.name
}

output "table_arn" {
  description = "ARN of the table (used by IAM policies)"
  value       = aws_dynamodb_table.image_metadata.arn
}

output "gsi_arn" {
  description = "ARN of the userId GSI (used by IAM policies)"
  value       = "${aws_dynamodb_table.image_metadata.arn}/index/userId-createdAt-index"
}

output "table_stream_arn" {
  description = "ARN of the table's DynamoDB Stream (if enabled later)"
  value       = aws_dynamodb_table.image_metadata.stream_arn
}
