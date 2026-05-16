resource "aws_iam_role" "rekognition" {
  name               = "${local.name_prefix}-rekognition-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  description = "Role for the Rekognition AI labeling Lambda"
}

data "aws_iam_policy_document" "rekognition" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/${local.name_prefix}-rekognition:*"]
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
    resources = [var.rekognition_queue_arn]
  }
  # Rekognition reads image directly from S3
  statement {
    sid       = "S3ReadForAI"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.upload_bucket_arn}/uploads/*"]
  }

  # Rekognition has NO resource-level permissions
  statement {
    sid    = "RekognitionDetect"
    effect = "Allow"
    actions = [
      "rekognition:DetectLabels",
      "rekognition:DetectModerationLabels",
    ]
    resources = ["*"]
  }

  # Update DynamoDB with labels
  statement {
    sid    = "DynamoDBWriteLabels"
    effect = "Allow"
    actions = [
      "dynamodb:UpdateItem",
      "dynamodb:GetItem",
    ]
    resources = [var.dynamodb_table_arn]
  }

  # Publish completion notification
  statement {
    sid       = "SNSPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.sns_topic_arn]
  }
}

resource "aws_iam_role_policy" "rekognition" {
  name   = "${local.name_prefix}-rekognition-policy"
  role   = aws_iam_role.rekognition.id
  policy = data.aws_iam_policy_document.rekognition.json
}
