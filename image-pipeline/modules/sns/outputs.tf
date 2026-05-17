output "user_notifications_arn" {
  value = aws_sns_topic.user_notifications.arn
}

output "ops_alerts_arn" {
  value = aws_sns_topic.ops_alerts.arn
}
