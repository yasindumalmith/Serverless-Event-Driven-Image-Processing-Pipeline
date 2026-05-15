locals {
  name_prefix = "${var.project}-${var.environment}"

  common_env = {
    ENVIRONMENT      = var.environment
    DYNAMODB_TABLE   = var.dynamodb_table_name
    UPLOAD_BUCKET    = var.upload_bucket_name
    PROCESSED_BUCKET = var.processed_bucket_name
  }
}

resource "aws_lambda_function" "presign" {
  function_name = "${local.name_prefix}-presign"
  description   = "Generates presigned S3 URLs for image uploads"
  role          = var.presign_role_arn
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  timeout       = 10
  memory_size   = 128

  filename         = "${path.module}/../../lambdas/presign/presign.zip"
  source_code_hash = filebase64sha256("${path.module}/../../lambdas/presign/presign.zip")

  environment {
    variables = local.common_env
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_cloudwatch_log_group" "presign" {
  name              = "/aws/lambda/${aws_lambda_function.presign.function_name}"
  retention_in_days = 14
}
