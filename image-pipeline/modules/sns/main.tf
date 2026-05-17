locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ── Topic for user-facing notifications (image complete/failed) ───────────────
resource "aws_sns_topic" "user_notifications" {
  name              = "${local.name_prefix}-user-notifications"
  display_name      = "Image Pipeline Notifications"
  kms_master_key_id = "alias/aws/sns"
}

# ── Topic for operator alerts (DLQ messages, system errors) ───────────────────
resource "aws_sns_topic" "ops_alerts" {
  name              = "${local.name_prefix}-ops-alerts"
  display_name      = "Image Pipeline Ops Alerts"
  kms_master_key_id = "alias/aws/sns"
}

# ── Subscribe the operator email to ops alerts ────────────────────────────────
resource "aws_sns_topic_subscription" "ops_email" {
  topic_arn = aws_sns_topic.ops_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
