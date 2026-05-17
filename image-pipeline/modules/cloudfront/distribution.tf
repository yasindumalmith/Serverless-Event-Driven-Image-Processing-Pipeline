resource "aws_cloudfront_distribution" "main" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${local.name_prefix} image pipeline"
  price_class     = var.price_class
  http_version    = "http2and3"
  web_acl_id      = var.waf_web_acl_arn

  # ── Origin — the processed S3 bucket via OAC ───────────────────────────────
  origin {
    domain_name              = var.processed_bucket_domain
    origin_id                = "s3-processed"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  # ── Default cache behaviour ────────────────────────────────────────────────
  default_cache_behavior {
    target_origin_id       = "s3-processed"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id = aws_cloudfront_cache_policy.images.id
  }

  # ── Restrictions ───────────────────────────────────────────────────────────
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # ── Use the default CloudFront SSL certificate ─────────────────────────────
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # ── Error responses — return clean 403/404 instead of S3 XML ───────────────
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 60
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 60
  }

  tags = {
    Name = "${local.name_prefix}-cloudfront"
  }
}
