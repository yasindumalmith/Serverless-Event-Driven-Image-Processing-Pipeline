data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "allow_cloudfront" {
  statement {
    sid    = "AllowCloudFrontOACRead"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${var.processed_bucket_arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "processed_cloudfront" {
  bucket = var.processed_bucket_id
  policy = data.aws_iam_policy_document.allow_cloudfront.json
}
