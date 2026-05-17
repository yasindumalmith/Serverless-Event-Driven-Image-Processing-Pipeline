output "queue_urls" {
  description = "Map of worker name to queue URL"
  value = {
    for k, v in aws_sqs_queue.main : k => v.url
  }
}

output "queue_arns" {
  description = "Map of worker name to queue ARN"
  value = {
    for k, v in aws_sqs_queue.main : k => v.arn
  }
}

output "dlq_urls" {
  description = "Map of worker name to DLQ URL"
  value = {
    for k, v in aws_sqs_queue.dlq : k => v.url
  }
}

output "dlq_arns" {
  description = "Map of worker name to DLQ ARN"
  value = {
    for k, v in aws_sqs_queue.dlq : k => v.arn
  }
}

# Direct references for convenience
output "resize_queue_url" { value = aws_sqs_queue.main["resize"].url }
output "resize_queue_arn" { value = aws_sqs_queue.main["resize"].arn }
output "watermark_queue_url" { value = aws_sqs_queue.main["watermark"].url }
output "watermark_queue_arn" { value = aws_sqs_queue.main["watermark"].arn }
output "rekognition_queue_url" { value = aws_sqs_queue.main["rekognition"].url }
output "rekognition_queue_arn" { value = aws_sqs_queue.main["rekognition"].arn }

output "resize_dlq_arn" { value = aws_sqs_queue.dlq["resize"].arn }
output "watermark_dlq_arn" { value = aws_sqs_queue.dlq["watermark"].arn }
output "rekognition_dlq_arn" { value = aws_sqs_queue.dlq["rekognition"].arn }
