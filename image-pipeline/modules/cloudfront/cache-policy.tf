# ── Long cache policy for images — they never change once processed ───────────
resource "aws_cloudfront_cache_policy" "images" {
  name        = "${local.name_prefix}-images-cache"
  comment     = "Long cache for immutable processed images"
  default_ttl = 86400    # 1 day default
  max_ttl     = 31536000 # 1 year maximum
  min_ttl     = 3600     # 1 hour minimum

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config { cookie_behavior = "none" }
    headers_config { header_behavior = "none" }
    query_strings_config { query_string_behavior = "none" }
  }
}
