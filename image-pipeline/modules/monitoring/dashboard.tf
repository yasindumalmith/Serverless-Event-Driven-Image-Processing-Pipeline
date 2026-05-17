locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # ── Row 1: Lambda invocations and errors ─────────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Lambda Invocations"
          region = var.aws_region
          metrics = [
            for name in values(var.lambda_function_names) :
            ["AWS/Lambda", "Invocations", "FunctionName", name, { stat = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Lambda Errors"
          region = var.aws_region
          metrics = [
            for name in values(var.lambda_function_names) :
            ["AWS/Lambda", "Errors", "FunctionName", name, { stat = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
        }
      },

      # ── Row 2: Lambda duration and SQS depth ─────────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Lambda Duration (avg)"
          region = var.aws_region
          metrics = [
            for name in values(var.lambda_function_names) :
            ["AWS/Lambda", "Duration", "FunctionName", name, { stat = "Average" }]
          ]
          view   = "timeSeries"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "SQS Queue Depth"
          region = var.aws_region
          metrics = [
            for name in values(var.sqs_queue_names) :
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", name, { stat = "Maximum" }]
          ]
          view   = "timeSeries"
          period = 60
        }
      },

      # ── Row 3: DLQ depth and DynamoDB ─────────────────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "DLQ Messages (any > 0 means trouble)"
          region = var.aws_region
          metrics = [
            for name in values(var.sqs_dlq_names) :
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", name, { stat = "Maximum" }]
          ]
          view   = "timeSeries"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "DynamoDB Throttles"
          region = var.aws_region
          metrics = [
            ["AWS/DynamoDB", "UserErrors", "TableName", var.dynamodb_table_name],
            ["AWS/DynamoDB", "ThrottledRequests", "TableName", var.dynamodb_table_name],
          ]
          view   = "timeSeries"
          period = 60
        }
      },

      # ── Row 4: API Gateway ─────────────────────────────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 24
        height = 6
        properties = {
          title  = "API Gateway Requests & Errors"
          region = var.aws_region
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", var.api_gateway_name, { stat = "Sum", label = "Total Requests" }],
            [".", "4xx", ".", ".", { stat = "Sum", label = "4xx Errors" }],
            [".", "5xx", ".", ".", { stat = "Sum", label = "5xx Errors" }],
          ]
          view   = "timeSeries"
          period = 60
        }
      },
    ]
  })
}
