locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${local.name_prefix}-oac"
  description                       = "OAC for image pipeline processed bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
