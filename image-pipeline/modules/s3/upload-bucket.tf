locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ── The upload bucket itself ──────────────────────────────────────────────────
resource "aws_s3_bucket" "upload" {
  bucket = "${local.name_prefix}-upload-${var.suffix}"

  # Don't accidentally let `terraform destroy` wipe user uploads
  # (set to false for dev — but always true for prod)
  force_destroy = var.environment != "prod"
}

# ── Versioning — keeps old versions if someone overwrites a file ──────────────
resource "aws_s3_bucket_versioning" "upload" {
  bucket = aws_s3_bucket.upload.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ── Server-side encryption — every object encrypted at rest ───────────────────
resource "aws_s3_bucket_server_side_encryption_configuration" "upload" {
  bucket = aws_s3_bucket.upload.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ── Block ALL public access — uploads are NEVER directly accessible ───────────
resource "aws_s3_bucket_public_access_block" "upload" {
  bucket = aws_s3_bucket.upload.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── CORS — allows browsers to PUT directly via presigned URL ──────────────────
resource "aws_s3_bucket_cors_configuration" "upload" {
  bucket = aws_s3_bucket.upload.id

  cors_rule {
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["*"] # tighten to your domain in production
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# ── Lifecycle — auto-delete originals after 30 days to save cost ──────────────
resource "aws_s3_bucket_lifecycle_configuration" "upload" {
  bucket = aws_s3_bucket.upload.id

  rule {
    id     = "delete-old-uploads"
    status = "Enabled"

    filter {
      prefix = "uploads/"
    }

    expiration {
      days = 30
    }

    # Also clean up old versions after 7 days
    noncurrent_version_expiration {
      noncurrent_days = 7
    }

    # Clean up incomplete multipart uploads after 1 day
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}
