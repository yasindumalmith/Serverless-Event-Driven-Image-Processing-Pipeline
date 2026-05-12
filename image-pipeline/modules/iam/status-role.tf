resource "aws_iam_role" "status" {
  name               = "${local.name_prefix}-status-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  description = "Role for the status/list API Lambda (read-only)"
}

data "aws_iam_policy_document" "status" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/${local.name_prefix}-status:*"]
  }

  # READ-ONLY DynamoDB — no PutItem, UpdateItem, or DeleteItem
  statement {
    sid    = "DynamoDBReadOnly"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query",
    ]
    resources = [
      var.dynamodb_table_arn,
      "${var.dynamodb_table_arn}/index/*", # GSI access
    ]
  }
}

resource "aws_iam_role_policy" "status" {
  name   = "${local.name_prefix}-status-policy"
  role   = aws_iam_role.status.id
  policy = data.aws_iam_policy_document.status.json
}
