resource "aws_lambda_function" "resize" {
  function_name = "${local.name_prefix}-resize"
  description   = "Resizes images to thumbnail, medium, and large sizes"
  role          = var.resize_role_arn
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  timeout       = 120
  memory_size   = 1024

  layers = [aws_lambda_layer_version.sharp.arn]

  filename         = "${path.module}/../../lambdas/resize/resize.zip"
  source_code_hash = filebase64sha256("${path.module}/../../lambdas/resize/resize.zip")

  environment {
    variables = local.common_env
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_cloudwatch_log_group" "resize" {
  name              = "/aws/lambda/${aws_lambda_function.resize.function_name}"
  retention_in_days = 14
}

# ── SQS → Resize Lambda event source mapping ──────────────────────────────────
resource "aws_lambda_event_source_mapping" "resize_sqs" {
  event_source_arn                   = var.resize_queue_arn
  function_name                      = aws_lambda_function.resize.arn
  batch_size                         = 1
  maximum_batching_window_in_seconds = 0
  function_response_types            = ["ReportBatchItemFailures"]
}
