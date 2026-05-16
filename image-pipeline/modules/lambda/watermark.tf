resource "aws_lambda_function" "watermark" {
  function_name = "${local.name_prefix}-watermark"
  description   = "Applies watermark to images"
  role          = var.watermark_role_arn
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  timeout       = 60
  memory_size   = 1024

  layers = [aws_lambda_layer_version.sharp.arn]

  filename         = "${path.module}/../../lambdas/watermark/watermark.zip"
  source_code_hash = filebase64sha256("${path.module}/../../lambdas/watermark/watermark.zip")

  environment {
    variables = merge(local.common_env, {
      WATERMARK_TEXT = "© My Image App"
    })
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_cloudwatch_log_group" "watermark" {
  name              = "/aws/lambda/${aws_lambda_function.watermark.function_name}"
  retention_in_days = 14
}

resource "aws_lambda_event_source_mapping" "watermark_sqs" {
  event_source_arn                   = var.watermark_queue_arn
  function_name                      = aws_lambda_function.watermark.arn
  batch_size                         = 1
  maximum_batching_window_in_seconds = 0
  function_response_types            = ["ReportBatchItemFailures"]
}
