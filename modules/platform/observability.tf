locals {
  application_log_group_name = format("/aws/containerinsights/%s/application", local.name)
}

# The CloudWatch Observability add-on writes container stdout/stderr here. If the
# group already exists, import it before the first apply instead of recreating it.
resource "aws_cloudwatch_log_group" "application" {
  name              = local.application_log_group_name
  retention_in_days = var.application_log_retention_days
}

resource "aws_cloudwatch_log_metric_filter" "circuit_opened" {
  name           = format("%s-circuit-opened", local.name)
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "{ $.event = \"geocoder.circuit.opened\" }"

  metric_transformation {
    name      = "CircuitBreakerOpened"
    namespace = "ShipmentTracking/Observability"
    value     = "1"
    dimensions = {
      Environment = "$.environment"
      Service     = "$.service"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "main_backlog" {
  name           = format("%s-main-backlog", local.name)
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "{ $.event = \"bullmq.backlog\" && $.queue = \"tracking-events\" }"

  metric_transformation {
    name      = "BullMQBacklog"
    namespace = "ShipmentTracking/Observability"
    value     = "$.backlog"
    dimensions = {
      Environment = "$.environment"
      Service     = "$.service"
      Queue       = "$.queue"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "dlq_backlog" {
  name           = format("%s-dlq-backlog", local.name)
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "{ $.event = \"bullmq.backlog\" && $.queue = \"tracking-events-dlq\" }"

  metric_transformation {
    name      = "BullMQBacklog"
    namespace = "ShipmentTracking/Observability"
    value     = "$.backlog"
    dimensions = {
      Environment = "$.environment"
      Service     = "$.service"
      Queue       = "$.queue"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "circuit_opened" {
  alarm_name          = format("%s-circuit-opened", local.name)
  alarm_description   = "Geocoder circuit breaker opened at least once in five minutes."
  actions_enabled     = false
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  metric_name         = "CircuitBreakerOpened"
  namespace           = "ShipmentTracking/Observability"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    Environment = var.environment
    Service     = "shipment-tracking-service"
  }
}

resource "aws_cloudwatch_metric_alarm" "main_backlog" {
  alarm_name          = format("%s-main-bullmq-backlog", local.name)
  alarm_description   = "Main BullMQ backlog reached 500 jobs for ten minutes."
  actions_enabled     = false
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  metric_name         = "BullMQBacklog"
  namespace           = "ShipmentTracking/Observability"
  period              = 600
  statistic           = "Maximum"
  threshold           = 500
  treat_missing_data  = "notBreaching"

  dimensions = {
    Environment = var.environment
    Service     = "shipment-tracking-service"
    Queue       = "tracking-events"
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_backlog" {
  alarm_name          = format("%s-dlq-bullmq-backlog", local.name)
  alarm_description   = "DLQ BullMQ backlog reached 500 jobs for ten minutes."
  actions_enabled     = false
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  metric_name         = "BullMQBacklog"
  namespace           = "ShipmentTracking/Observability"
  period              = 600
  statistic           = "Maximum"
  threshold           = 500
  treat_missing_data  = "notBreaching"

  dimensions = {
    Environment = var.environment
    Service     = "shipment-tracking-service"
    Queue       = "tracking-events-dlq"
  }
}
