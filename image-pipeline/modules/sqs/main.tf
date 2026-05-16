locals {
  name_prefix = "${var.project}-${var.environment}"

  queues = ["resize", "watermark", "rekognition"]
}

# ── Dead Letter Queues (must be created BEFORE the main queues) ───────────────
resource "aws_sqs_queue" "dlq" {
  for_each = toset(local.queues)

  name                      = "${local.name_prefix}-${each.key}-dlq"
  message_retention_seconds = 1209600 # 14 days — max allowed by SQS

  tags = {
    Name = "${local.name_prefix}-${each.key}-dlq"
    Type = "dead-letter-queue"
  }
}

# ── Main processing queues ────────────────────────────────────────────────────
resource "aws_sqs_queue" "main" {
  for_each = toset(local.queues)

  name                       = "${local.name_prefix}-${each.key}-queue"
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = 86400  # 1 day
  receive_wait_time_seconds  = 20     # long polling reduces empty receives
  max_message_size           = 262144 # 256 KB max — we send small JSON

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = {
    Name       = "${local.name_prefix}-${each.key}-queue"
    WorkerType = each.key
  }
}
