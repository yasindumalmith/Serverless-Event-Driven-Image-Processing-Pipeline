resource "aws_lambda_function" "trigger" {
  function_name = "${local.name_prefix}-trigger"
  description   = "Receives S3 events, validates uploads, fans out to worker queues"
  role          = var.trigger_role_arn
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  timeout       = 30
  memory_size   = 256

  filename         = "${path.module}/../../lambdas/trigger/trigger.zip"
  source_code_hash = filebase64sha256("${path.module}/../../lambdas/trigger/trigger.zip")

  environment {
    variables = merge(local.common_env, {
      RESIZE_QUEUE_URL      = var.resize_queue_url
      WATERMARK_QUEUE_URL   = var.watermark_queue_url
      REKOGNITION_QUEUE_URL = var.rekognition_queue_url
    })
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_cloudwatch_log_group" "trigger" {
  name              = "/aws/lambda/${aws_lambda_function.trigger.function_name}"
  retention_in_days = 14
}

# ── Permission for S3 to invoke the trigger Lambda ────────────────────────────
resource "aws_lambda_permission" "s3_trigger" {
  statement_id  = "AllowS3InvokeTrigger"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.upload_bucket_arn
}

# ── S3 event notification that invokes the trigger Lambda ─────────────────────
resource "aws_s3_bucket_notification" "upload_events" {
  bucket = var.upload_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.trigger.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
  }

  depends_on = [aws_lambda_permission.s3_trigger]
}
