# ── Alarm: any message in any DLQ (signals permanent failure) ─────────────────
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  for_each = var.sqs_dlq_names

  alarm_name          = "${local.name_prefix}-dlq-${each.key}-not-empty"
  alarm_description   = "Messages in ${each.key} DLQ — indicates permanent failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = each.value
  }

  alarm_actions = [var.ops_alerts_topic_arn]
}

# ── Alarm: Lambda error rate ──────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = var.lambda_function_names

  alarm_name          = "${local.name_prefix}-lambda-${each.key}-errors"
  alarm_description   = "Lambda ${each.key} has errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = each.value
  }

  alarm_actions = [var.ops_alerts_topic_arn]
}

# ── Alarm: SQS queue backing up (workers can't keep up) ───────────────────────
resource "aws_cloudwatch_metric_alarm" "queue_depth" {
  for_each = var.sqs_queue_names

  alarm_name          = "${local.name_prefix}-queue-${each.key}-backing-up"
  alarm_description   = "${each.key} queue depth too high — workers falling behind"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 100
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = each.value
  }

  alarm_actions = [var.ops_alerts_topic_arn]
}

# ── Alarm: oldest message age (workers stalled) ───────────────────────────────
resource "aws_cloudwatch_metric_alarm" "oldest_message" {
  for_each = var.sqs_queue_names

  alarm_name          = "${local.name_prefix}-queue-${each.key}-oldest-message"
  alarm_description   = "${each.key} queue has messages older than 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 300 # 5 minutes
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = each.value
  }

  alarm_actions = [var.ops_alerts_topic_arn]
}
