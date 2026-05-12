output "presign_role_arn" {
  description = "ARN of the presign Lambda role"
  value       = aws_iam_role.presign.arn
}

output "trigger_role_arn" {
  description = "ARN of the trigger Lambda role"
  value       = aws_iam_role.trigger.arn
}

output "resize_role_arn" {
  description = "ARN of the resize Lambda role"
  value       = aws_iam_role.resize.arn
}

output "watermark_role_arn" {
  description = "ARN of the watermark Lambda role"
  value       = aws_iam_role.watermark.arn
}

output "rekognition_role_arn" {
  description = "ARN of the rekognition Lambda role"
  value       = aws_iam_role.rekognition.arn
}

output "status_role_arn" {
  description = "ARN of the status Lambda role"
  value       = aws_iam_role.status.arn
}

output "dlq_handler_role_arn" {
  description = "ARN of the DLQ handler Lambda role"
  value       = aws_iam_role.dlq_handler.arn
}

# Convenience: all role ARNs as a map for outputs/debugging
output "all_role_arns" {
  description = "All Lambda role ARNs as a map"
  value = {
    presign     = aws_iam_role.presign.arn
    trigger     = aws_iam_role.trigger.arn
    resize      = aws_iam_role.resize.arn
    watermark   = aws_iam_role.watermark.arn
    rekognition = aws_iam_role.rekognition.arn
    status      = aws_iam_role.status.arn
    dlq_handler = aws_iam_role.dlq_handler.arn
  }
}
