locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_dynamodb_table" "image_metadata" {
  name         = "${local.name_prefix}-image-metadata"
  billing_mode = "PAY_PER_REQUEST"

  # ── Primary key — every item is identified by imageId ───────────────────────
  hash_key = "imageId"

  # ── Attributes referenced by keys or indexes must be declared here ──────────
  # (other attributes can be stored without declaring — DynamoDB is schemaless)
  attribute {
    name = "imageId"
    type = "S" # String
  }

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  # ── Global Secondary Index — lets us query images by userId ─────────────────
  global_secondary_index {
    name            = "userId-createdAt-index"
    hash_key        = "userId"
    range_key       = "createdAt"
    projection_type = "ALL" # include all attributes in the index
  }

  # ── Point-in-time recovery — restore to any moment in the last 35 days ──────
  point_in_time_recovery {
    enabled = var.environment == "prod"
  }

  # ── Encryption at rest — always on ──────────────────────────────────────────
  server_side_encryption {
    enabled = true
  }

  # ── TTL — items can auto-delete based on a timestamp attribute ──────────────
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  # ── Deletion protection in prod ─────────────────────────────────────────────
  deletion_protection_enabled = var.environment == "prod"

  tags = {
    Name = "${local.name_prefix}-image-metadata"
  }
}
