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
