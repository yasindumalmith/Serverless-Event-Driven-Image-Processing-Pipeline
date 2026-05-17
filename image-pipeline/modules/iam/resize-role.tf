resource "aws_iam_role" "resize" {
  name               = "${local.name_prefix}-resize-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  description = "Role for the resize worker Lambda"
}

data "aws_iam_policy_document" "resize" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/${local.name_prefix}-resize:*"]
  }

  # SQS: consume from main processing queue
  statement {
    sid    = "SQSConsume"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [var.resize_queue_arn]
  }

  # S3 READ: only from upload bucket
  statement {
    sid       = "S3ReadOriginal"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.upload_bucket_arn}/uploads/*"]
  }

  # S3 WRITE: only to processed bucket
  statement {
    sid    = "S3WriteProcessed"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]
    resources = ["${var.processed_bucket_arn}/processed/*"]
  }

  statement {
    sid       = "DynamoDBUpdateStatus"
    effect    = "Allow"
    actions   = ["dynamodb:UpdateItem"]
    resources = [var.dynamodb_table_arn]
  }

  statement {
    sid       = "XRayTracing"
    effect    = "Allow"
    actions   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "resize" {
  name   = "${local.name_prefix}-resize-policy"
  role   = aws_iam_role.resize.id
  policy = data.aws_iam_policy_document.resize.json
}
