resource "aws_iam_role" "trigger" {
  name               = "${local.name_prefix}-trigger-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  description = "Role for the trigger Lambda that handles S3 events"
}

data "aws_iam_policy_document" "trigger" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/${local.name_prefix}-trigger:*"]
  }

  # S3: read uploaded file for validation
  statement {
    sid    = "S3ReadUpload"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectAttributes",
    ]
    resources = ["${var.upload_bucket_arn}/uploads/*"]
  }

  # SQS: send job to processing queue
  statement {
    sid    = "SQSSendToAllQueues"
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [
      var.resize_queue_arn,
      var.watermark_queue_arn,
      var.rekognition_queue_arn,
    ]
  }

  # DynamoDB: update status to "processing"
  statement {
    sid    = "DynamoDBUpdateStatus"
    effect = "Allow"
    actions = [
      "dynamodb:UpdateItem",
      "dynamodb:GetItem",
    ]
    resources = [var.dynamodb_table_arn]
  }

  # X-Ray tracing
  statement {
    sid       = "XRayTracing"
    effect    = "Allow"
    actions   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "trigger" {
  name   = "${local.name_prefix}-trigger-policy"
  role   = aws_iam_role.trigger.id
  policy = data.aws_iam_policy_document.trigger.json
}
