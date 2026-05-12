# ── The processed bucket — holds resized and watermarked images ───────────────
resource "aws_s3_bucket" "processed" {
  bucket        = "${local.name_prefix}-processed-${var.suffix}"
  force_destroy = var.environment != "prod"
}

# ── Encryption ────────────────────────────────────────────────────────────────
resource "aws_s3_bucket_server_side_encryption_configuration" "processed" {
  bucket = aws_s3_bucket.processed.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ── Block public access — CloudFront will be the only way to access ───────────
resource "aws_s3_bucket_public_access_block" "processed" {
  bucket = aws_s3_bucket.processed.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── Lifecycle — keep processed images longer than originals ───────────────────
resource "aws_s3_bucket_lifecycle_configuration" "processed" {
  bucket = aws_s3_bucket.processed.id

  rule {
    id     = "transition-old-images"
    status = "Enabled"

    filter {
      prefix = "processed/"
    }

    # Move to cheaper storage after 90 days
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    # Even cheaper after 365 days
    transition {
      days          = 365
      storage_class = "GLACIER"
    }
  }
}
