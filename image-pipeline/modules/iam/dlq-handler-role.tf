resource "aws_iam_role" "dlq_handler" {
  name               = "${local.name_prefix}-dlq-handler-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  description = "Role for the dead-letter queue handler"
}

data "aws_iam_policy_document" "dlq_handler" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/${local.name_prefix}-dlq-handler:*"]
  }

  # SQS: ONLY the DLQ — not the main queue
  statement {
    sid    = "DLQConsume"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [var.sqs_dlq_arn]
  }

  # Mark failed in DynamoDB
  statement {
    sid       = "DynamoDBMarkFailed"
    effect    = "Allow"
    actions   = ["dynamodb:UpdateItem"]
    resources = [var.dynamodb_table_arn]
  }

  # Notify user of failure
  /*statement {
    sid       = "SNSPublishFailure"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.sns_topic_arn]
  }*/
}

resource "aws_iam_role_policy" "dlq_handler" {
  name   = "${local.name_prefix}-dlq-handler-policy"
  role   = aws_iam_role.dlq_handler.id
  policy = data.aws_iam_policy_document.dlq_handler.json
}
