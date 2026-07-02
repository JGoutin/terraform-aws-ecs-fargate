/*
ECS service & task
*/

resource "aws_ecs_service" "main" {
  name                               = "${local.name}-service"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.main.arn
  desired_count                      = local.autoscaling_min_capacity
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  propagate_tags                     = "TASK_DEFINITION"
  tags                               = var.tags
  deployment_minimum_healthy_percent = 100
  enable_execute_command             = var.enable_execute_command ? true : null
  triggers = merge(var.triggers, {
    # Trigger on secrets update
    for ssm_parameter in aws_ssm_parameter.main :
    ssm_parameter.arn => ssm_parameter.version
  })
  deployment_circuit_breaker {
    rollback = true
    enable   = true
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100 - var.autoscaling_spot_percent
    base = coalesce(
      var.autoscaling_spot_on_demand_min_capacity,
      local.autoscaling_min_capacity
    )
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = var.autoscaling_spot_percent
  }
  network_configuration {
    subnets          = var.subnets_ids
    security_groups  = concat([aws_security_group.main.id], var.security_group_ids)
    assign_public_ip = var.assign_public_ip
  }
  dynamic "load_balancer" {
    for_each = merge([
      for name, port_mapping in local.port_mappings : {
        for idx, tg_arn in coalesce(port_mapping.target_group_arns, []) :
        "${name}_${idx}" => {
          target_group_arn = tg_arn
          container_name   = port_mapping.container_name
          container_port   = port_mapping.container_port
        }
      }
    ]...)
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }
  dynamic "service_connect_configuration" {
    for_each = toset(local.service_connect_enabled ? [1] : [])
    content {
      enabled   = true
      namespace = var.service_discovery_http_namespace_arn
      log_configuration {
        log_driver = "awslogs"
        options = {
          awslogs-region        = data.aws_region.current.region
          awslogs-group         = aws_cloudwatch_log_group.service.name
          awslogs-stream-prefix = "${local.name}-"
        }
      }
      dynamic "service" {
        for_each = local.port_mappings
        content {
          discovery_name = service.key
          port_name      = service.value.port_name
          client_alias {
            dns_name = service.key
            port     = service.value.container_port
          }
        }
      }
    }
  }
  dynamic "service_registries" {
    for_each = local.service_registries_enabled ? local.port_mappings : {}
    content {
      container_name = service_registries.value.container_name
      container_port = service_registries.value.container_port
      registry_arn   = aws_service_discovery_service.main[0].arn
    }
  }
  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${local.name}-task-definition"
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu * 1024
  memory                   = var.memory
  network_mode             = "awsvpc"
  tags                     = var.tags
  runtime_platform {
    cpu_architecture        = var.cpu_architecture
    operating_system_family = "LINUX"
  }
  dynamic "ephemeral_storage" {
    for_each = toset(var.ephemeral_storage_size_in_gib != null ? [1] : [])
    content {
      size_in_gib = var.ephemeral_storage_size_in_gib
    }
  }
  dynamic "volume" {
    # EFS volumes
    for_each = local.mount_points_efs
    content {
      name = volume.key
      efs_volume_configuration {
        file_system_id     = aws_efs_access_point.mount_points[volume.key].file_system_id
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = aws_efs_access_point.mount_points[volume.key].id
        }
      }
    }
  }
  dynamic "volume" {
    # Ephemeral storage volumes
    for_each = toset([for key, efs in local.mount_points : key if !efs])
    content {
      name = volume.key
    }
  }
  container_definitions = nonsensitive(jsonencode(
    [for definition_name, definition in var.container_definitions :
      { for filter_key, filter_value in {
        command      = definition.command
        cpu          = try(definition.cpu * 1024, null)
        dockerLabels = definition.docker_labels
        entryPoint   = definition.entrypoint
        essential    = definition.essential
        environment = [for name, value in coalesce(definition.environment, {}) : {
          name  = name
          value = tostring(value)
        } if value != null]
        dependsOn = [for container_name, condition in coalesce(definition.depends_on, {}) : {
          containerName = container_name
          condition     = upper(condition)
        }]
        healthCheck = definition.health_check != null ? { for k, v in {
          command     = definition.health_check.command
          interval    = definition.health_check.interval
          timeout     = definition.health_check.timeout
          retries     = definition.health_check.retries
          startPeriod = definition.health_check.start_period
        } : k => v if v != null } : null
        image       = definition.image
        interactive = definition.interactive
        linuxParameters = definition.linux_parameters != null ? { for k, v in {
          capabilities       = definition.linux_parameters.capabilities
          initProcessEnabled = definition.linux_parameters.init_process_enabled
        } : k => v if v != null } : null
        logConfiguration = {
          logDriver = "awslogs"
          options = merge(
            {
              awslogs-region        = data.aws_region.current.region
              awslogs-group         = aws_cloudwatch_log_group.container[definition_name].name
              awslogs-stream-prefix = "${local.name}-${definition_name}-"
            },
            definition.log_configuration != null ? { for k, v in {
              awslogs-datetime-format   = definition.log_configuration.datetime_format
              awslogs-multiline-pattern = definition.log_configuration.multiline_pattern
              max-buffer-size           = definition.log_configuration.multiline_pattern
              mode                      = definition.log_configuration.blocking ? "blocking" : null
            } : k => v if v != null } : {}
          )
        }
        memory            = definition.memory
        memoryReservation = definition.memory_reservation
        mountPoints = [for source_volume, mount_point in coalesce(definition.mount_points, {}) : { for k, v in {
          sourceVolume  = source_volume
          containerPath = mount_point.container_path
          readOnly      = mount_point.read_only
        } : k => v if v != null }]
        name                   = definition_name
        pseudoTerminal         = definition.pseudo_terminal
        readonlyRootFilesystem = definition.read_only_root_filesystem
        restartPolicy = definition.restart_policy != null ? { for k, v in {
          enabled              = definition.restart_policy.enabled
          ignoredExitCodes     = definition.restart_policy.ignored_exit_codes
          restartAttemptPeriod = definition.restart_policy.restart_attempt_period
        } : k => v if v != null } : null
        portMappings = [for name, port_mapping in coalesce(definition.port_mappings, {}) : { for k, v in {
          name               = name
          appProtocol        = port_mapping.app_protocol
          containerPort      = port_mapping.container_port
          containerPortRange = port_mapping.container_port_range
          hostPort           = port_mapping.host_port
          hostPortRange      = port_mapping.host_port_range
          protocol           = port_mapping.protocol
        } : k => v if v != null }]
        secrets = [for name in keys(coalesce(definition.secrets, {})) : {
          name      = name
          valueFrom = aws_ssm_parameter.main["${definition_name}-${name}"].arn
        }]
        startTimeout = definition.start_timeout
        stopTimeout  = definition.stop_timeout
        systemControls = [for namespace, value in coalesce(definition.system_controls, {}) : {
          namespace = namespace
          value     = value
        }]
        ulimits = [for name, ulimit in coalesce(definition.ulimits, {}) : {
          name      = name
          hardLimit = ulimit.hard_limit
          softLimit = coalesce(ulimit.soft_limit, ulimit.hard_limit)
        }]
        user               = definition.user
        versionConsistency = definition.version_consistency
        volumesFrom        = []
        workingDirectory   = definition.working_directory
        } : filter_key => filter_value if
        filter_value != null
      }
    ]
  ))
}
