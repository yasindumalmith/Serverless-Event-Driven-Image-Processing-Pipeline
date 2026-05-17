output "presign_function_name" {
  value = aws_lambda_function.presign.function_name
}

output "presign_invoke_arn" {
  value = aws_lambda_function.presign.invoke_arn
}

output "status_function_name" {
  value = aws_lambda_function.status.function_name
}

output "status_invoke_arn" {
  value = aws_lambda_function.status.invoke_arn
}


output "trigger_function_name" {
  value = aws_lambda_function.trigger.function_name
}

output "trigger_function_arn" {
  value = aws_lambda_function.trigger.arn
}

output "resize_function_name" {
  value = aws_lambda_function.resize.function_name
}

output "resize_function_arn" {
  value = aws_lambda_function.resize.arn
}

output "watermark_function_name" {
  value = aws_lambda_function.watermark.function_name
}

output "watermark_function_arn" {
  value = aws_lambda_function.watermark.arn
}

output "rekognition_function_name" {
  value = aws_lambda_function.rekognition.function_name
}

output "rekognition_function_arn" {
  value = aws_lambda_function.rekognition.arn
}

output "dlq_handler_function_name" {
  value = aws_lambda_function.dlq_handler.function_name
}

output "dlq_handler_function_arn" {
  value = aws_lambda_function.dlq_handler.arn
}

