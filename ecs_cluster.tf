/*
ECS cluster
*/

locals {
  cluster_name = "${local.name}-cluster"
}

resource "aws_ecs_cluster" "main" {
  name = local.cluster_name
  tags = { "Name" = local.cluster_name }
  configuration {
    dynamic "execute_command_configuration" {
      for_each = toset(var.enable_execute_command ? [1] : [])
      content {
        kms_key_id = module.kms_key.id
        logging    = "OVERRIDE"
        log_configuration {
          cloud_watch_encryption_enabled = true
          cloud_watch_log_group_name     = aws_cloudwatch_log_group.execute_command[0].name
        }
      }
    }
    managed_storage_configuration {
      kms_key_id                           = module.kms_key.id
      fargate_ephemeral_storage_kms_key_id = module.kms_key.arn
    }
  }
  setting {
    name  = "containerInsights"
    value = var.container_insight
  }
  depends_on = [module.kms_key.policy_dependency]
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}
