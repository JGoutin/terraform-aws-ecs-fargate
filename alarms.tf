/*
CloudWatch Alarms for ECS Service monitoring
*/

# High Memory Usage Alarm
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  for_each            = var.alarms_enabled ? toset(["enabled"]) : toset([])
  alarm_name          = "${local.name}-high-memory"
  tags                = var.tags
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 4
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "This metric monitors ECS service memory utilization"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }
}

# Container Unhealthy Status Alarm
resource "aws_cloudwatch_metric_alarm" "unhealthy_containers" {
  for_each            = var.alarms_enabled ? toset(["enabled"]) : toset([])
  alarm_name          = "${local.name}-unhealthy-containers"
  tags                = var.tags
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 4
  metric_name         = "HealthCheckFailed"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "This metric monitors ECS container health check failures"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }
}

# CPU Anomaly Detection
resource "aws_cloudwatch_metric_alarm" "cpu_anomaly" {
  for_each                  = var.alarms_enabled ? toset(["enabled"]) : toset([])
  alarm_name                = "${local.name}-cpu-anomaly"
  tags                      = var.tags
  comparison_operator       = "GreaterThanUpperThreshold"
  evaluation_periods        = 5
  datapoints_to_alarm       = 4
  threshold_metric_id       = "ad1"
  alarm_description         = "This metric monitors ECS service CPU utilization when higher than expected pattern"
  alarm_actions             = [var.sns_topic_arn]
  ok_actions                = [var.sns_topic_arn]
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []

  metric_query {
    id          = "m1"
    return_data = true
    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/ECS"
      period      = 60
      stat        = "Average"
      dimensions = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.main.name
      }
    }
  }

  metric_query {
    id          = "ad1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 3)"
    label       = "CPUUtilization (expected)"
    return_data = true
  }
}

# Autoscaling at Maximum Capacity Alarm
resource "aws_cloudwatch_metric_alarm" "max_capacity_reached" {
  for_each            = var.alarms_enabled && local.autoscaling_min_capacity != local.autoscaling_max_capacity && var.container_insight != "disabled" ? toset(["enabled"]) : toset([])
  alarm_name          = "${local.name}-max-capacity-reached"
  tags                = var.tags
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 4
  metric_name         = "DesiredTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = local.autoscaling_max_capacity
  alarm_description   = "This metric monitors when ECS service reaches maximum autoscaling capacity"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }
}
