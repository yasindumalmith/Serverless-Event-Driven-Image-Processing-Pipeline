resource "aws_lambda_function" "rekognition" {
  function_name = "${local.name_prefix}-rekognition"
  description   = "Extracts AI labels and moderation status via AWS Rekognition"
  role          = var.rekognition_role_arn
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  timeout       = 60
  memory_size   = 256

  filename         = "${path.module}/../../lambdas/rekognition/rekognition.zip"
  source_code_hash = filebase64sha256("${path.module}/../../lambdas/rekognition/rekognition.zip")

  environment {
    variables = merge(local.common_env, {
      MAX_LABELS     = "20"
      MIN_CONFIDENCE = "75"
    })
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_cloudwatch_log_group" "rekognition" {
  name              = "/aws/lambda/${aws_lambda_function.rekognition.function_name}"
  retention_in_days = 14
}

resource "aws_lambda_event_source_mapping" "rekognition_sqs" {
  event_source_arn                   = var.rekognition_queue_arn
  function_name                      = aws_lambda_function.rekognition.arn
  batch_size                         = 5
  maximum_batching_window_in_seconds = 5
  function_response_types            = ["ReportBatchItemFailures"]
}
