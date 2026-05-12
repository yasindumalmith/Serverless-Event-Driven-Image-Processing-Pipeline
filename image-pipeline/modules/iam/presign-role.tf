resource "aws_iam_role" "presign" {
  name               = "${local.name_prefix}-presign-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  description = "Role for the presign Lambda that generates S3 upload URLs"
}

data "aws_iam_policy_document" "presign" {
  # CloudWatch Logs
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/${local.name_prefix}-presign:*"]
  }

  # S3: only allowed to PutObject on the uploads/ prefix of upload bucket
  statement {
    sid    = "S3PresignedUpload"
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = ["${var.upload_bucket_arn}/uploads/*"]
  }

  # DynamoDB: create the initial pending record
  statement {
    sid       = "DynamoDBCreateRecord"
    effect    = "Allow"
    actions   = ["dynamodb:PutItem"]
    resources = [var.dynamodb_table_arn]
  }
}

resource "aws_iam_role_policy" "presign" {
  name   = "${local.name_prefix}-presign-policy"
  role   = aws_iam_role.presign.id
  policy = data.aws_iam_policy_document.presign.json
}
