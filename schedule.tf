/*
Scheduled service start/stop
*/

resource "aws_appautoscaling_scheduled_action" "stop" {
  count              = var.autoscaling_schedule_stop != null ? 1 : 0
  name               = "${local.name}-stop"
  schedule           = var.autoscaling_schedule_stop
  resource_id        = aws_appautoscaling_target.main.resource_id
  service_namespace  = aws_appautoscaling_target.main.service_namespace
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  scalable_target_action {
    min_capacity = 0
    max_capacity = 0
  }
}

resource "aws_appautoscaling_scheduled_action" "start" {
  count              = var.autoscaling_schedule_start != null ? 1 : 0
  name               = "${local.name}-start"
  schedule           = var.autoscaling_schedule_start
  resource_id        = aws_appautoscaling_target.main.resource_id
  service_namespace  = aws_appautoscaling_target.main.service_namespace
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  scalable_target_action {
    min_capacity = local.autoscaling_min_capacity
    max_capacity = local.autoscaling_max_capacity
  }
}
