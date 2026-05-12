locals {
  name_prefix = "${var.project}-${var.environment}"
}

# This trust policy is shared by every Lambda role.
# It says: "Allow AWS Lambda service to assume this role"
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    sid     = "AllowLambdaServiceAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
