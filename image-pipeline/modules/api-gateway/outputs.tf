output "api_endpoint" {
  description = "Base URL for the API"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "api_id" {
  value = aws_apigatewayv2_api.main.id
}

output "api_name" {
  value = aws_apigatewayv2_api.main.name
}
