resource "aws_lambda_function" "status" {
  function_name = "${local.name_prefix}-status"
  description   = "Returns image status and lists user images"
  role          = var.status_role_arn
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  timeout       = 10
  memory_size   = 128

  filename         = "${path.module}/../../lambdas/status/status.zip"
  source_code_hash = filebase64sha256("${path.module}/../../lambdas/status/status.zip")

  environment {
    variables = local.common_env
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_cloudwatch_log_group" "status" {
  name              = "/aws/lambda/${aws_lambda_function.status.function_name}"
  retention_in_days = 14
}
