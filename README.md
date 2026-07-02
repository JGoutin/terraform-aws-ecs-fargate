# AWS ECS Fargate Deployment Module

[![Terraform Module](https://img.shields.io/badge/Terraform-ECS%20Fargate%20module-844FBA?logo=terraform&logoColor=ffffff)](https://registry.terraform.io/modules/jgoutin/ecs-fargate/aws/latest)
[![OpenTofu Module](https://img.shields.io/badge/OpenTofu-ECS%20Fargate%20module-FFDA18?logo=opentofu&logoColor=ffffff)](https://search.opentofu.org/module/jgoutin/ecs-fargate/aws/latest)

Comprehensive Terraform module for deploying and managing containerized applications on AWS ECS Fargate with auto-scaling, monitoring, and production-grade features.

## Overview

This module provides a complete ECS Fargate deployment solution with built-in auto-scaling, monitoring, and security features.

**Core Components:**
- ECS Cluster with Container Insights
- ECS Fargate Service (serverless containers)
- Auto-scaling policies (CPU, memory, ALB-based)
- CloudWatch alarms with anomaly detection
- Service Discovery via AWS Cloud Map
- Security groups and IAM roles

## Features

### Compute
- ✅ **ECS Fargate** - Serverless container orchestration
- ✅ **Flexible Sizing** - 0.25-16 vCPU, 0.5-120 GB RAM
- ✅ **Multi-Container Support** - Sidecar patterns
- ✅ **Health Checks** - Docker HEALTHCHECK integration
- ✅ **ARM64 & x86_64** - CPU architecture selection

### Auto-scaling
- ✅ **Target Tracking** - CPU, memory, ALB requests
- ✅ **Scheduled Scaling** - Start/stop on cron schedule
- ✅ **Cooldown Periods** - Separate scale-in/scale-out
- ✅ **Min/Max Capacity** - 0-1000 tasks

### Monitoring
- ✅ **Container Insights** - Enhanced/enabled/disabled modes
- ✅ **4 CloudWatch Alarms** - High memory, unhealthy containers, CPU anomaly, max capacity
- ✅ **SNS Integration** - Alert notifications
- ✅ **CloudWatch Logs** - Per-container log groups with retention

### Networking
- ✅ **VPC Integration** - Private subnet deployment
- ✅ **Security Groups** - Automatic or user-provided
- ✅ **Service Discovery** - AWS Cloud Map DNS
- ✅ **ALB Integration** - Target group attachment

## Quick Start

### Minimal Example

```hcl
module "ecs_service" {
  source = "JGoutin/ecs-fargate/aws"
  
  name           = "my-app"
  vpc_id         = "vpc-xxxxx"
  subnet_ids     = ["subnet-1", "subnet-2"]
  container_image = "nginx:latest"
  
  container_definitions = {
    main = {
      port_mappings = {
        http = { container_port = 80 }
      }
    }
  }
}
```

### Production Example

```hcl
module "ecs_service" {
  source = "JGoutin/ecs-fargate/aws""
  
  name       = "my-app-prod"
  vpc_id     = "vpc-xxxxx"
  subnet_ids = ["subnet-a", "subnet-b", "subnet-c"]
  
  # Container Configuration
  container_image = "my-app:v1.2.3"
  cpu             = 2     # 2 vCPU
  memory          = 4096  # 4 GB
  
  container_definitions = {
    main = {
      port_mappings = {
        http = { container_port = 8080 }
      }
      environment = {
        ENV = "production"
      }
      health_check = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        start_period = 60
      }
    }
  }
  
  # Auto-scaling
  autoscaling_enabled      = true
  autoscaling_min_capacity = 3
  autoscaling_max_capacity = 10
  autoscaling_cpu_target_percent    = 70
  autoscaling_memory_target_percent = 80
  
  # Monitoring
  container_insight = "enhanced"
  sns_topic_arn     = "arn:aws:sns:us-east-1:123456789012:alerts"
  
  # Service Discovery
  service_discovery_dns_namespace_id = "ns-xxxxx"
  service_discovery_dns_name         = "my-app"
}
```

### With ALB Integration

```hcl
module "ecs_service" {
  source = "JGoutin/ecs-fargate/aws""
  
  name       = "web-app"
  vpc_id     = "vpc-xxxxx"
  subnet_ids = ["subnet-1", "subnet-2"]
  
  container_image = "my-web-app:latest"
  
  container_definitions = {
    web = {
      port_mappings = {
        http = { container_port = 8080 }
      }
    }
  }
  
  # ALB Integration
  alb_target_group_arn = aws_lb_target_group.main.arn
  alb_container_name   = "web"
  alb_container_port   = 8080
}
```

## Architecture

```
┌─────────────────────────────────────────┐
│              VPC                        │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │     ECS Cluster                   │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │   ECS Fargate Service       │  │  │
│  │  │  ┌────────┐    ┌────────┐   │  │  │
│  │  │  │ Task 1 │    │ Task 2 │   │  │  │
│  │  │  │┌──────┐│    │┌──────┐│   │  │  │
│  │  │  ││ App  ││    ││ App  ││   │  │  │
│  │  │  │└──────┘│    │└──────┘│   │  │  │
│  │  │  └────────┘    └────────┘   │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
│           │                             │
│  ┌────────▼──────────────────┐          │
│  │  Auto-scaling Policies    │          │
│  │  - CPU Target Tracking    │          │
│  │  - Memory Target Tracking │          │
│  │  - ALB Requests Tracking  │          │
│  └───────────────────────────┘          │
│           │                             │
│  ┌────────▼──────────────────┐          │
│  │  CloudWatch Alarms        │          │
│  │  - High Memory (90%)      │          │
│  │  - Unhealthy Containers   │          │
│  │  - CPU Anomaly Detection  │          │
│  │  - Max Capacity Reached   │          │
│  └───────┬───────────────────┘          │
│          │                              │
└──────────┼──────────────────────────────┘
           │
    ┌──────▼────────┐
    │  SNS Topic    │
    │  (Alerts)     │
    └───────────────┘
```

## Use Cases

- **Web Applications** - API servers, web services
- **Microservices** - Service mesh deployments
- **Batch Processing** - Scheduled ECS tasks
- **Background Workers** - Queue consumers
- **AI/ML Inference** - Model serving
- **Data Processing** - ETL pipelines

## Container Insights Modes

| Mode | Description | Metrics | Cost |
|------|-------------|---------|------|
| `enhanced` | Full metrics + network/storage | All ECS metrics | Higher |
| `enabled` | Task-level metrics only | Basic ECS metrics | Medium |
| `disabled` | No Container Insights | CloudWatch agent only | Lowest |

**Recommendation:** Use `enhanced` for production, `disabled` for cost-sensitive environments.

## Auto-scaling Behavior

**Scale-out triggers:**
- CPU > target (default 70%)
- Memory > target (default 80%)
- ALB requests per target > threshold (default 1000)

**Scale-in triggers:**
- All metrics < target for cooldown period (default 300s)

**Limits:**
- Min capacity: 0-1000 tasks (default: # of AZs)
- Max capacity: 1-1000 tasks (default: 10)

## CloudWatch Alarms

When `sns_topic_arn` is specified:

1. **High Memory Alarm** - Triggers when memory > 90% for 4/5 datapoints
2. **Unhealthy Containers** - Triggers on any HealthCheckFailed metric
3. **CPU Anomaly** - Triggers when CPU exceeds 3-sigma historical pattern
4. **Max Capacity** - Triggers when DesiredTaskCount = max_capacity (requires Container Insights)

## Scheduled Scaling

Start/stop service on schedule:

```hcl
autoscaling_schedule_stop  = "cron(0 18 * * ? *)"  # Stop at 6 PM UTC daily
autoscaling_schedule_start = "cron(0 6 * * ? *)"   # Start at 6 AM UTC daily
```

Format: AWS EventBridge cron expressions (UTC timezone)

## Service Discovery

AWS Cloud Map integration for private DNS:

```hcl
service_discovery_dns_namespace_id = "ns-xxxxx"
service_discovery_dns_name         = "my-service"
service_discovery_dns_ttl          = 10
```

Accessible at: `my-service.namespace.local`

## Security

- ✅ **Private Subnets** - No public IP assignment
- ✅ **Security Groups** - Least-privilege rules
- ✅ **IAM Roles** - Separate execution & task roles
- ✅ **Secrets Management** - Systems Manager Parameter Store
- ✅ **Read-only Root Filesystem** - Optional
- ✅ **Non-privileged Containers** - Default

## Outputs

Key outputs for integration:

- `ecs_cluster_name` - For AWS CLI/SDK
- `ecs_service_name` - For monitoring/scaling
- `security_group_id` - For security group rules
- `service_discovery_service_name` - For DNS resolution
- `cloudwatch_log_groups_names` - For log aggregation

## Requirements

- **Terraform/OpenTofu**: >= 1.5.0
- **AWS Provider**: >= 5.0
- **VPC**: Existing VPC with subnets
- **Container Image**: Accessible from ECS (ECR, Docker Hub, etc.)

---

# Terraform Documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >=5 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | JGoutin/kms-key/aws | ~> 1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.alb_requests](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.memory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_scheduled_action.start](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_scheduled_action) | resource |
| [aws_appautoscaling_scheduled_action.stop](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_scheduled_action) | resource |
| [aws_appautoscaling_target.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_backup_plan.mount_points](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_selection.mount_points](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_vault.mount_points](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_cloudwatch_log_group.container](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.container_insight](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.execute_command](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.cpu_anomaly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.high_memory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.max_capacity_reached](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.unhealthy_containers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_ecs_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |
| [aws_ecs_service.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_efs_access_point.mount_points](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point) | resource |
| [aws_efs_file_system.mount_points](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_mount_target.mount_points](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_iam_policy.execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.backup_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.backup_restore_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.backup_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.mount_points](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_service_discovery_service.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [aws_ssm_parameter.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_vpc_security_group_egress_rule.connect_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.connect_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.mount_points](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.connect_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.connect_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.mount_points](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.backup_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.execution_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.tasks_role_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnet.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarms_enabled"></a> [alarms\_enabled](#input\_alarms\_enabled) | Enable CloudWatch alarms. This should be set to true if sns\_topic\_arn is provided. | `bool` | `false` | no |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Assign a public IP address to the ENI. | `bool` | `null` | no |
| <a name="input_autoscaling_alb_resource_label"></a> [autoscaling\_alb\_resource\_label](#input\_autoscaling\_alb\_resource\_label) | ALB resource label for request-based scaling (format: app/load-balancer-name/xxx/targetgroup/target-group-name/yyy). Required if autoscaling\_alb\_target\_requests\_per\_target is set. | `string` | `null` | no |
| <a name="input_autoscaling_alb_target_requests_per_target"></a> [autoscaling\_alb\_target\_requests\_per\_target](#input\_autoscaling\_alb\_target\_requests\_per\_target) | Target number of ALB requests per ECS task for auto-scaling. If null, request-based scaling is disabled. | `number` | `null` | no |
| <a name="input_autoscaling_cpu_target_percent"></a> [autoscaling\_cpu\_target\_percent](#input\_autoscaling\_cpu\_target\_percent) | Percent of CPU to use as target for autoscaling. If null, uses AWS default. | `number` | `null` | no |
| <a name="input_autoscaling_max_capacity"></a> [autoscaling\_max\_capacity](#input\_autoscaling\_max\_capacity) | Maximum capacity for autoscaling. If set to the same value than var.autoscaling\_min\_capacity, autoscaling is disabled. If not specified, the 5 x subnets count in used. | `number` | `null` | no |
| <a name="input_autoscaling_memory_target_percent"></a> [autoscaling\_memory\_target\_percent](#input\_autoscaling\_memory\_target\_percent) | Target memory utilization percentage for auto-scaling. If null, memory-based scaling is disabled. | `number` | `null` | no |
| <a name="input_autoscaling_min_capacity"></a> [autoscaling\_min\_capacity](#input\_autoscaling\_min\_capacity) | Minimum capacity for autoscaling. If not specified, the subnets count in used. | `number` | `null` | no |
| <a name="input_autoscaling_scale_in_cooldown"></a> [autoscaling\_scale\_in\_cooldown](#input\_autoscaling\_scale\_in\_cooldown) | Time in seconds after a scale-in activity completes before another scale-in can start. If null, uses AWS default. | `number` | `null` | no |
| <a name="input_autoscaling_scale_out_cooldown"></a> [autoscaling\_scale\_out\_cooldown](#input\_autoscaling\_scale\_out\_cooldown) | Time in seconds after a scale-out activity completes before another scale-out can start. If null, uses AWS default. | `number` | `null` | no |
| <a name="input_autoscaling_schedule_start"></a> [autoscaling\_schedule\_start](#input\_autoscaling\_schedule\_start) | If Specified, schedule service start if paused by var.autoscaling\_schedule\_pause\_cron\_expression. The following formats are supported: At expressions - at(yyyy-mm-ddThh:mm:ss), Rate expressions - rate(valueunit), Cron expressions - cron(fields). In UTC | `string` | `null` | no |
| <a name="input_autoscaling_schedule_stop"></a> [autoscaling\_schedule\_stop](#input\_autoscaling\_schedule\_stop) | If Specified, schedule service stop/pause (By scaling to 0). The following formats are supported: At expressions - at(yyyy-mm-ddThh:mm:ss), Rate expressions - rate(valueunit), Cron expressions - cron(fields). In UTC. | `string` | `null` | no |
| <a name="input_autoscaling_spot_on_demand_min_capacity"></a> [autoscaling\_spot\_on\_demand\_min\_capacity](#input\_autoscaling\_spot\_on\_demand\_min\_capacity) | Minimum of on-demand capacity when var.autoscaling\_spot\_percent is enabled. If not specified, same as the var.autoscaling\_min\_capacity value. | `number` | `null` | no |
| <a name="input_autoscaling_spot_percent"></a> [autoscaling\_spot\_percent](#input\_autoscaling\_spot\_percent) | Percent of capacity over the minimum capacity to run with Fargate Spot. | `number` | `0` | no |
| <a name="input_cloudwatch_logs_retention_in_days"></a> [cloudwatch\_logs\_retention\_in\_days](#input\_cloudwatch\_logs\_retention\_in\_days) | Cloudwatch logs retention in days. | `number` | `365` | no |
| <a name="input_container_definitions"></a> [container\_definitions](#input\_container\_definitions) | ECS task containers definition. See ECS task definition parameters documentation for more information on each parameter (Convert parameter name from snake case to camel case). | <pre>map(object({<br/>    command       = optional(list(string))<br/>    cpu           = optional(number)<br/>    depends_on    = optional(map(string)) # Map of other containers of the task to depends on. With container name as key and condition as value. The map conversion to 'containerName'/'condition' key pairs is automatically handled.<br/>    docker_labels = optional(map(string))<br/>    entrypoint    = optional(list(string))<br/>    essential     = optional(bool, true)<br/>    environment   = optional(map(string)) # Map of environment variable. The map conversion to 'name'/'value' key pairs is automatically handled. null values are ignored.<br/>    health_check = optional(object({<br/>      command      = list(string)<br/>      timeout      = optional(number)<br/>      retries      = optional(number)<br/>      interval     = optional(number)<br/>      start_period = optional(number)<br/>    }))<br/>    image       = string # Only ECR image are supported for now (ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/REPOSITORY_NAME:TAG or ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/REPOSITORY_NAME@HASH)<br/>    interactive = optional(bool)<br/>    linux_parameters = optional(object({<br/>      capabilities = optional(object({<br/>        add  = optional(list(string), [])<br/>        drop = optional(list(string), [])<br/>      }))<br/>      init_process_enabled = optional(bool)<br/>    }))<br/>    log_configuration = optional(object({<br/>      # Cloudwatch log groups are automatically created with "awslogs" driver. Theses parameters are options for this driver.<br/>      blocking          = optional(bool) # If 'true', set mode to 'blocking', else to 'non-blocking', the default ECS mode.<br/>      datetime_format   = optional(string)<br/>      max_buffer_size   = optional(string)<br/>      multiline_pattern = optional(string)<br/>    }))<br/>    memory             = optional(number)<br/>    memory_reservation = optional(number)<br/>    mount_points = optional(map(object({<br/>      container_path = string<br/>      read_only      = optional(bool)<br/>      efs            = optional(bool) # If true, an EFS file-system is automatically created with a mount target for each specified mount point, else ephemeral storage is used.<br/>    })))<br/>    port_mappings = optional(map(object({<br/>      app_protocol         = optional(string)<br/>      container_port       = number<br/>      container_port_range = optional(string)<br/>      host_port            = optional(number)<br/>      host_port_range      = optional(string)<br/>      protocol             = optional(string)<br/>      target_group_arns    = optional(list(string)) # Optional target groups ARNs to connect to this port.<br/>    })))<br/>    pseudo_terminal           = optional(bool)<br/>    read_only_root_filesystem = optional(bool)<br/>    restart_policy = optional(object({<br/>      enabled                = bool<br/>      ignored_exit_codes     = optional(list(number))<br/>      restart_attempt_period = optional(number)<br/>    }))<br/>    secrets         = optional(map(string)) # Map of sensitive values to pass as environment variables. The secure storage using SSM parameters is automatically handled.<br/>    start_timeout   = optional(number)<br/>    stop_timeout    = optional(number)<br/>    system_controls = optional(map(string)) # Map of system controls to set. With namespace as key and value as value. The map conversion to 'namespace'/'value' key pairs is automatically handled.<br/>    ulimits = optional(map(object({<br/>      # Key is the type of the ulimit. Currently, only "nofile" is supported (Fargate limitation).<br/>      hard_limit = number<br/>      soft_limit = optional(number) # Use "hard_limit" value if not specified.<br/>    })))<br/>    user                = optional(string)<br/>    version_consistency = optional(bool)<br/>    working_directory   = optional(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_container_insight"></a> [container\_insight](#input\_container\_insight) | Container insight configuration. Valid values: 'enhanced', 'enabled', 'disabled'. Default to 'enabled'. | `string` | `"enabled"` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | ECS task CPU count. Valid values: 0.25, 0.5, 1, 2, 4, 8 & 16. Default of 0.25 vCPU is suitable for common use cases (text generation, embeddings). Increase for intensive workloads (multimodal requests, large LLM models). | `number` | `0.25` | no |
| <a name="input_cpu_architecture"></a> [cpu\_architecture](#input\_cpu\_architecture) | CPU architecture. Valid values: 'X86\_64' or 'ARM64'. | `string` | `"X86_64"` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | If true, enable deletion protection on eligible resources. | `bool` | `false` | no |
| <a name="input_enable_execute_command"></a> [enable\_execute\_command](#input\_enable\_execute\_command) | Whether to enable Amazon ECS Exec for the tasks within the service. | `bool` | `false` | no |
| <a name="input_ephemeral_storage_size_in_gib"></a> [ephemeral\_storage\_size\_in\_gib](#input\_ephemeral\_storage\_size\_in\_gib) | The amount of ephemeral storage to allocate for the task. This parameter is used to expand the total amount of ephemeral storage available, beyond the default amount, for tasks hosted on AWS Fargate. | `number` | `null` | no |
| <a name="input_health_check_grace_period_seconds"></a> [health\_check\_grace\_period\_seconds](#input\_health\_check\_grace\_period\_seconds) | Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 2147483647. Only valid for services configured to use load balancers. | `number` | `null` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | If specified, directly use this KMS key instead of creating a dedicated one for the application. | `string` | `null` | no |
| <a name="input_kms_policy_dependency"></a> [kms\_policy\_dependency](#input\_kms\_policy\_dependency) | To use with 'depends\_on' for resources requiring that KMS policy for key from this module is updated before creation. Only if var.kms\_key\_id is not set. | `list(any)` | `[]` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | ECS task memory (MiB). Valid values depends on the var.cpu value (x1024), see the ECS documentation for more information. Default of 512 MiB is suitable for common use cases (text generation, embeddings). Increase for intensive workloads (multimodal requests, large LLM models). | `number` | `512` | no |
| <a name="input_mount_points_backup_enable"></a> [mount\_points\_backup\_enable](#input\_mount\_points\_backup\_enable) | If 'true', enable AWS Backup for mount points. | `bool` | `true` | no |
| <a name="input_mount_points_backup_retention_days"></a> [mount\_points\_backup\_retention\_days](#input\_mount\_points\_backup\_retention\_days) | Number of days to retain backups for mount points. If null, uses AWS default. | `number` | `null` | no |
| <a name="input_mount_points_performance_mode"></a> [mount\_points\_performance\_mode](#input\_mount\_points\_performance\_mode) | The EFS performance mode of the EFS file system used for mount points. Valid values: 'generalPurpose' or 'maxIO'. Default to 'generalPurpose'. | `string` | `null` | no |
| <a name="input_mount_points_provisioned_throughput_in_mibps"></a> [mount\_points\_provisioned\_throughput\_in\_mibps](#input\_mount\_points\_provisioned\_throughput\_in\_mibps) | The throughput, measured in MiB/s, that you want to provision for the EFS file system used for mount points. Required only when var.mount\_points\_throughput\_mode = 'provisioned'. | `number` | `null` | no |
| <a name="input_mount_points_throughput_mode"></a> [mount\_points\_throughput\_mode](#input\_mount\_points\_throughput\_mode) | The EFS throughput mode of the EFS file system used for mount points. Valid values: 'bursting', 'provisioned', or 'elastic'. Defaults to 'bursting'. When using 'provisioned', also set var.mount\_points\_provisioned\_throughput\_in\_mibps. | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix to add to all created resources names. | `string` | `"ecs"` | no |
| <a name="input_security_group_connect_egress"></a> [security\_group\_connect\_egress](#input\_security\_group\_connect\_egress) | Add these egress rules to the ECS service security group. Also add the matching ingress rules to the source security groups, allowing them to communicate without extra configuration. | <pre>map(object({ # Key is rule description<br/>    from_port                    = number<br/>    protocol                     = optional(string, "tcp")<br/>    referenced_security_group_id = string<br/>    to_port                      = optional(number) # Default to "from_port" value<br/>  }))</pre> | `{}` | no |
| <a name="input_security_group_connect_ingress"></a> [security\_group\_connect\_ingress](#input\_security\_group\_connect\_ingress) | Add these ingress rules to the ECS service security group. Also add the matching egress rules to the source security groups, allowing them to communicate without extra configuration. | <pre>map(object({ # Key is rule description<br/>    from_port                    = number<br/>    protocol                     = optional(string, "tcp")<br/>    referenced_security_group_id = string<br/>    to_port                      = optional(number) # Default to "from_port" value<br/>  }))</pre> | `{}` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Add theses extra security group to the ECS service. | `list(string)` | `[]` | no |
| <a name="input_security_group_rules_egress"></a> [security\_group\_rules\_egress](#input\_security\_group\_rules\_egress) | Add these egress rules to the ECS service security group. | <pre>map(object({ # Key is rule description<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    from_port                    = number<br/>    prefix_list_id               = optional(string)<br/>    protocol                     = optional(string, "tcp")<br/>    referenced_security_group_id = optional(string)<br/>    to_port                      = optional(number) # Default to "from_port" value<br/>  }))</pre> | `{}` | no |
| <a name="input_security_group_rules_ingress"></a> [security\_group\_rules\_ingress](#input\_security\_group\_rules\_ingress) | Add these ingress rules to the ECS service security group. | <pre>map(object({ # Key is rule description<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    from_port                    = number<br/>    prefix_list_id               = optional(string)<br/>    protocol                     = optional(string, "tcp")<br/>    referenced_security_group_id = optional(string)<br/>    to_port                      = optional(number) # Default to "from_port" value<br/>  }))</pre> | `{}` | no |
| <a name="input_service_discovery_dns_health_check_failure_threshold"></a> [service\_discovery\_dns\_health\_check\_failure\_threshold](#input\_service\_discovery\_dns\_health\_check\_failure\_threshold) | Service discovery health check failure threshold. Only if var.service\_discovery\_dns\_namespace\_id is true. If null, uses AWS default. | `number` | `null` | no |
| <a name="input_service_discovery_dns_name"></a> [service\_discovery\_dns\_name](#input\_service\_discovery\_dns\_name) | If specified, use this DNS name. By default, use the resource name. Only if var.service\_discovery\_dns\_namespace\_id is specified. | `string` | `null` | no |
| <a name="input_service_discovery_dns_namespace_id"></a> [service\_discovery\_dns\_namespace\_id](#input\_service\_discovery\_dns\_namespace\_id) | If specified, enable Service discovery on the ECS service and attach it to this namespace. | `string` | `null` | no |
| <a name="input_service_discovery_dns_ttl"></a> [service\_discovery\_dns\_ttl](#input\_service\_discovery\_dns\_ttl) | Service discovery TTL for DNS entries. Only if var.service\_discovery\_dns\_namespace\_id is specified. If null, uses AWS default. | `number` | `null` | no |
| <a name="input_service_discovery_http_namespace_arn"></a> [service\_discovery\_http\_namespace\_arn](#input\_service\_discovery\_http\_namespace\_arn) | If specified, enable Service connect on the ECS service and attach it to this namespace. | `string` | `null` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | SNS topic ARN for CloudWatch alarms. If specified, CloudWatch alarms will be created for high memory usage and unhealthy containers. | `string` | `null` | no |
| <a name="input_subnets_ids"></a> [subnets\_ids](#input\_subnets\_ids) | Subnets where to deploy the service. | `list(string)` | n/a | yes |
| <a name="input_task_role_policies"></a> [task\_role\_policies](#input\_task\_role\_policies) | List of extra IAM policies ARNs to attach to the task role. | `list(string)` | `[]` | no |
| <a name="input_triggers"></a> [triggers](#input\_triggers) | Map of arbitrary keys and values that, when changed, will trigger an in-place update (redeployment). | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_log_groups_names"></a> [cloudwatch\_log\_groups\_names](#output\_cloudwatch\_log\_groups\_names) | Log group names for each containers. |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | ECS cluster name. |
| <a name="output_ecs_service_name"></a> [ecs\_service\_name](#output\_ecs\_service\_name) | ECS service name. |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | KMS key ARN. |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | KMS key ID. |
| <a name="output_kms_policy_dependency"></a> [kms\_policy\_dependency](#output\_kms\_policy\_dependency) | To use with 'depends\_on' for resources requiring that KMS policy is updated before creation. Only if var.kms\_key\_id is set. |
| <a name="output_kms_policy_documents_json"></a> [kms\_policy\_documents\_json](#output\_kms\_policy\_documents\_json) | KMS policy documents to add to the policy of the key specified via var.kms\_key\_id. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ECS service security group ID |
| <a name="output_service_discovery_service_name"></a> [service\_discovery\_service\_name](#output\_service\_discovery\_service\_name) | Service discovery service name. Only if var.service\_discovery\_dns\_namespace\_id is defined. |
<!-- END_TF_DOCS -->