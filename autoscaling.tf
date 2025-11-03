/*
Autoscaling based on CPU.
*/

locals {
  autoscaling_min_capacity = var.autoscaling_min_capacity != null ? var.autoscaling_min_capacity : length(var.subnets_ids)
  autoscaling_max_capacity = max(var.autoscaling_max_capacity != null ? var.autoscaling_max_capacity : length(var.subnets_ids) * 5, local.autoscaling_min_capacity)
}

resource "aws_appautoscaling_target" "main" {
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = local.autoscaling_min_capacity
  max_capacity       = local.autoscaling_max_capacity
}

resource "aws_appautoscaling_policy" "cpu" {
  count              = local.autoscaling_min_capacity != local.autoscaling_max_capacity && var.autoscaling_cpu_target_percent != null ? 1 : 0
  name               = "${local.name}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  service_namespace  = aws_appautoscaling_target.main.service_namespace
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_cpu_target_percent
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "memory" {
  count              = local.autoscaling_min_capacity != local.autoscaling_max_capacity && var.autoscaling_memory_target_percent != null ? 1 : 0
  name               = "${local.name}-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  service_namespace  = aws_appautoscaling_target.main.service_namespace
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_memory_target_percent
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "alb_requests" {
  count              = local.autoscaling_min_capacity != local.autoscaling_max_capacity && var.autoscaling_alb_target_requests_per_target != null && var.autoscaling_alb_resource_label != null ? 1 : 0
  name               = "${local.name}-alb-requests"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  service_namespace  = aws_appautoscaling_target.main.service_namespace
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_alb_target_requests_per_target
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = var.autoscaling_alb_resource_label
    }
  }
}
