resource "aws_lambda_function" "dlq_handler" {
  function_name = "${local.name_prefix}-dlq-handler"
  description   = "Handles permanently failed messages from all worker DLQs"
  role          = var.dlq_handler_role_arn
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  timeout       = 30
  memory_size   = 256

  filename         = "${path.module}/../../lambdas/dlq-handler/dlq-handler.zip"
  source_code_hash = filebase64sha256("${path.module}/../../lambdas/dlq-handler/dlq-handler.zip")

  environment {
    variables = merge(local.common_env, {
      OPS_ALERTS_ARN = var.ops_alerts_topic_arn
    })
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_cloudwatch_log_group" "dlq_handler" {
  name              = "/aws/lambda/${aws_lambda_function.dlq_handler.function_name}"
  retention_in_days = 30 # keep DLQ logs longer for investigation
}

# ── Wire all 3 DLQs to the same Lambda ────────────────────────────────────────
resource "aws_lambda_event_source_mapping" "resize_dlq" {
  event_source_arn        = var.resize_dlq_arn
  function_name           = aws_lambda_function.dlq_handler.arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_lambda_event_source_mapping" "watermark_dlq" {
  event_source_arn        = var.watermark_dlq_arn
  function_name           = aws_lambda_function.dlq_handler.arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_lambda_event_source_mapping" "rekognition_dlq" {
  event_source_arn        = var.rekognition_dlq_arn
  function_name           = aws_lambda_function.dlq_handler.arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
}
