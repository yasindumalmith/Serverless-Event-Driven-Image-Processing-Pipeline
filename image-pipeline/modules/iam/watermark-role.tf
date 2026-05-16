resource "aws_iam_role" "watermark" {
  name               = "${local.name_prefix}-watermark-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  description = "Role for the watermark Lambda"
}

data "aws_iam_policy_document" "watermark" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/${local.name_prefix}-watermark:*"]
  }

  statement {
    sid    = "SQSConsume"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [var.watermark_queue_arn]
  }

  # ONLY processed bucket — cannot touch upload bucket
  statement {
    sid    = "S3ProcessedReadWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${var.processed_bucket_arn}/processed/*"]
  }

  statement {
    sid       = "S3ReadOriginalForWatermark"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.upload_bucket_arn}/uploads/*"]
  }

  statement {
    sid       = "DynamoDBUpdateStatus"
    effect    = "Allow"
    actions   = ["dynamodb:UpdateItem"]
    resources = [var.dynamodb_table_arn]
  }
}

resource "aws_iam_role_policy" "watermark" {
  name   = "${local.name_prefix}-watermark-policy"
  role   = aws_iam_role.watermark.id
  policy = data.aws_iam_policy_document.watermark.json
}
