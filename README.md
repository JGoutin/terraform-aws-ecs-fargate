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
- **AWS Provider**: >= 6.27.0
- **VPC**: Existing VPC with subnets
- **Container Image**: Accessible from ECS (ECR, Docker Hub, etc.)

## Security Hub Controls

AWS Security Hub (FSBP) controls relevant to the resources this module manages:

Severity: 🔴 Critical · 🟠 High · 🟡 Medium · 🔵 Low

| Control | Severity | Title | Status | Options to pass |
|---|---|---|---|---|
| ECS.2 | 🟠 High | ECS services should not have public IP addresses assigned to them automatically | ⚠️ Conditional (default: ✅ Pass) | Keep `assign_public_ip = null` (default, resolves to `DISABLED`) or set it to `false` explicitly. |
| ECS.3 | 🟠 High | ECS task definitions should not share the host's process namespace | ✅ Pass | Not exposed as an option; the module never sets `pid_mode` and Fargate always isolates the PID namespace per task. |
| ECS.4 | 🟠 High | ECS containers should run as non-privileged | ✅ Pass | Not exposed as an option; `container_definitions` has no `privileged` field, and Fargate doesn't support privileged containers. |
| ECS.5 | 🟠 High | ECS task definitions should be configured to use read-only root filesystems | ⚠️ Conditional (default: ❌ Fail) | Set `read_only_root_filesystem = true` on every entry of `container_definitions` to pass. It defaults to unset (root filesystem writable), which fails the control. |
| ECS.8 | 🟠 High | Secrets should not be passed as container environment variables | ✅ Pass, if used as intended | Put sensitive values in each container's `secrets` map (backed by KMS-encrypted SSM `SecureString` parameters), never in `environment`. |
| ECS.9 | 🟠 High | ECS task definitions should have a logging configuration | ✅ Pass | The `awslogs` log driver is always configured; not configurable/optional. |
| ECS.10 | 🟡 Medium | ECS Fargate services should run on the latest Fargate platform version | ✅ Pass | `platform_version` is not exposed/set, so ECS defaults to `LATEST`. |
| ECS.12 | 🟡 Medium | ECS clusters should use Container Insights | ⚠️ Conditional (default: ✅ Pass) | Keep `container_insight` at `"enabled"` (default) or `"enhanced"` to pass. Setting it to `"disabled"` — as suggested elsewhere in this README for cost-sensitive environments — fails this control. |
| ECS.13 | 🔵 Low | ECS services should be tagged | ⚠️ Conditional (default: ❌ Fail) | Set `tags` to pass. The service resource applies `var.tags` as-is (default `null`), so it ships untagged — failing this control — unless you supply tags. |
| ECS.14 | 🔵 Low | ECS clusters should be tagged | ✅ Pass | The cluster always receives a `Name` tag regardless of `tags`. |
| ECS.15 | 🔵 Low | ECS task definitions should be tagged | ⚠️ Conditional (default: ❌ Fail) | Set `tags` to pass. Same issue as ECS.13 — the task definition also applies `var.tags` as-is, so it ships untagged unless you supply tags. |
| ECS.16 | 🟠 High | ECS task sets should not automatically assign public IP addresses | ⬜ N/A | Module manages `aws_ecs_service` directly and never creates `aws_ecs_task_set` resources. |
| ECS.17 | 🟡 Medium | ECS task definitions should not use host network mode | ✅ Pass | `network_mode` is hardcoded to `"awsvpc"`; not configurable. |
| ECS.18 | 🟡 Medium | ECS task definitions should use in-transit encryption for EFS volumes | ✅ Pass | `transit_encryption = "ENABLED"` is hardcoded for any container using an EFS mount point; not configurable. |
| ECS.19 | 🟡 Medium | ECS capacity providers should have managed termination protection enabled | ⬜ N/A | Only the AWS-managed `FARGATE`/`FARGATE_SPOT` capacity providers are used; this control applies to EC2 Auto Scaling group-backed providers. |
| ECS.20 | 🟡 Medium | ECS task definitions should configure non-root users for Linux containers | ⚠️ Conditional (default: ❌ Fail) | Set `user` (e.g. a non-root UID/name supported by the image) on every entry of `container_definitions` to pass. It defaults to unset, which fails the control. |
| ECS.21 | 🟡 Medium | ECS task definitions should configure non-administrator users for Windows containers | ⬜ N/A | `operating_system_family` is hardcoded to `"LINUX"`. |
| EFS.1 / EFS.8 | 🟡 Medium | EFS should encrypt file data at-rest using AWS KMS / EFS file systems should be encrypted at rest | ✅ Pass | `encrypted = true` with a customer-managed KMS key is hardcoded for any EFS mount point created by this module; not configurable. |
| EFS.2 | 🟡 Medium | EFS volumes should be in backup plans | ⚠️ Conditional (default: ✅ Pass) | Keep `mount_points_backup_enable = true` (default) to pass. Setting it to `false` removes the AWS Backup selection and fails the control. |
| EFS.3 | 🟡 Medium | EFS access points should enforce a root directory | ✅ Pass | Each access point's root directory is `/${each.key}` (the mount point key), never `/`. |
| EFS.4 | 🟡 Medium | EFS access points should enforce a user identity | ⚠️ Conditional (default: ❌ Fail) | Set `efs_posix_user` (`uid`/`gid`) on the relevant entry of `container_definitions.*.mount_points` to pass. It defaults to unset, which fails the control. |
| EFS.5 | 🔵 Low | EFS access points should be tagged | ✅ Pass | Access points are tagged via `local.tags`. |
| EFS.6 | 🟡 Medium | EFS mount targets should not be associated with subnets that assign public IPs on launch | ⚠️ Conditional (default: depends on caller-supplied subnets — cannot be determined by this module) | Depends entirely on the subnets passed via `subnets_ids` — use subnets with `map_public_ip_on_launch = false` (e.g. the app subnets from the companion `terraform-aws-vpc` module) to pass. |
| EFS.7 | 🟡 Medium | EFS file systems should have automatic backups enabled | ⚠️ Conditional (default: ❌ Fail) | Set `mount_points_efs_backup_enable = true` (default `false`) to pass — it enables EFS's native backup policy independently of `mount_points_backup_enable` (the custom AWS Backup plan, on by default). Off by default since it adds cost on top of the already-enabled custom plan. |
| CloudWatch.15 | 🟠 High | CloudWatch alarms should have specified actions configured | ⚠️ Conditional (default: N/A — no alarms are created) | Set `alarms_enabled = true` and `sns_topic_arn` to pass. Alarms are only created when both are supplied (defaults: `alarms_enabled = false`, `sns_topic_arn = null`); with no alarm resources, there is nothing for the control to evaluate. |
| CloudWatch.16 | 🟡 Medium | CloudWatch log groups should be retained for a specified time period (AWS default: ≥365 days) | ⚠️ Conditional (default: ✅ Pass) | Keep `cloudwatch_logs_retention_in_days` at `365` or more (default `365`) to pass — it applies to every log group this module creates, including the Container Insights performance log group. Lowering it fails this control. |
| CloudWatch.17 | 🟠 High | CloudWatch alarm actions should be activated | ✅ Pass | `actions_enabled` is never set on the alarms, so it defaults to `true`. |
| Backup.1 | 🟡 Medium | Backup recovery points should be encrypted at rest | ✅ Pass | The backup vault (`aws_backup_vault.mount_points`) sets `kms_key_arn`. |
| Backup.2 / Backup.3 / Backup.5 | 🔵 Low | Backup recovery points / vaults / plans should be tagged | ✅ Pass | All are tagged via `local.tags`; recovery points inherit tags from the source EFS file system. |
| IAM.1 | 🟠 High | IAM policies should not allow full "*" administrative privileges | ✅ Pass | No execution/task role policy statement grants `Action:"*"`/`Resource:"*"`. |
| IAM.24 | 🔵 Low | IAM roles should be tagged | ✅ Pass | Execution, task, and backup IAM roles are all tagged via `local.tags`. |
| EC2.13 / EC2.14 / EC2.18 / EC2.53 / EC2.54 | 🟠 High | Security groups should not allow unrestricted/admin-port ingress from 0.0.0.0/0 or ::/0 | ⚠️ Conditional (default: ✅ Pass) | The module's own security groups (`aws_security_group.main`, `aws_security_group.mount_points`) have no ingress rules by default. Adding an entry to `security_group_rules_ingress` (or `security_group_connect_ingress`) with `cidr_ipv4 = "0.0.0.0/0"` / `cidr_ipv6 = "::/0"` fails these controls — scope custom ingress rules to specific CIDRs or security groups instead. |
| EC2.19 | 🔴 Critical | Security groups should not allow unrestricted access to ports with high risk | ⚠️ Conditional (default: ✅ Pass) | Same reasoning and remediation as EC2.13/14/18/53/54 above — no ingress rules by default. |
| EC2.43 | 🔵 Low | EC2 security groups should be tagged | ✅ Pass | Both security groups are tagged via `local.tags`. |

---

# Terraform Documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.27.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.27.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | JGoutin/kms-key/aws | ~> 1.2 |

## Resources

| Name | Type |
| ---- | ---- |
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
| [aws_efs_backup_policy.mount_points](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_backup_policy) | resource |
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
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_alarms_enabled"></a> [alarms\_enabled](#input\_alarms\_enabled) | Enable CloudWatch alarms. This should be set to true if sns\_topic\_arn is provided. | `bool` | `false` | no |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Assign a public IP address to the ENI. Security Hub: ECS.2 (ECS services should not have public IP addresses assigned to them automatically) — default null (resolves to DISABLED) = pass; setting true fails this control. | `bool` | `null` | no |
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
| <a name="input_cloudwatch_logs_retention_in_days"></a> [cloudwatch\_logs\_retention\_in\_days](#input\_cloudwatch\_logs\_retention\_in\_days) | Cloudwatch logs retention in days. Applies to every log group this module creates (service, per-container, execute-command, and Container Insights performance). Security Hub: CloudWatch.16 (CloudWatch log groups should be retained for a specified time period) requires at least 365 days by default — default 365 = pass; lowering it fails this control. | `number` | `365` | no |
| <a name="input_container_definitions"></a> [container\_definitions](#input\_container\_definitions) | ECS task containers definition. See ECS task definition parameters documentation for more information on each parameter (Convert parameter name from snake case to camel case). | <pre>map(object({<br/>    command       = optional(list(string))<br/>    cpu           = optional(number)<br/>    depends_on    = optional(map(string)) # Map of other containers of the task to depends on. With container name as key and condition as value. The map conversion to 'containerName'/'condition' key pairs is automatically handled.<br/>    docker_labels = optional(map(string))<br/>    entrypoint    = optional(list(string))<br/>    essential     = optional(bool, true)<br/>    environment   = optional(map(string)) # Map of environment variable. The map conversion to 'name'/'value' key pairs is automatically handled. null values are ignored. Security Hub ECS.8: never put secrets here, use 'secrets' below instead.<br/>    health_check = optional(object({<br/>      command      = list(string)<br/>      timeout      = optional(number)<br/>      retries      = optional(number)<br/>      interval     = optional(number)<br/>      start_period = optional(number)<br/>    }))<br/>    image       = string # Only ECR image are supported for now (ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/REPOSITORY_NAME:TAG or ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/REPOSITORY_NAME@HASH)<br/>    interactive = optional(bool)<br/>    linux_parameters = optional(object({<br/>      capabilities = optional(object({<br/>        add  = optional(list(string), [])<br/>        drop = optional(list(string), [])<br/>      }))<br/>      init_process_enabled = optional(bool)<br/>    }))<br/>    log_configuration = optional(object({<br/>      # Cloudwatch log groups are automatically created with "awslogs" driver. Theses parameters are options for this driver.<br/>      blocking          = optional(bool) # If 'true', set mode to 'blocking', else to 'non-blocking', the default ECS mode.<br/>      datetime_format   = optional(string)<br/>      max_buffer_size   = optional(string)<br/>      multiline_pattern = optional(string)<br/>    }))<br/>    memory             = optional(number)<br/>    memory_reservation = optional(number)<br/>    mount_points = optional(map(object({<br/>      container_path = string<br/>      read_only      = optional(bool)<br/>      efs            = optional(bool) # If true, an EFS file-system is automatically created with a mount target for each specified mount point, else ephemeral storage is used.<br/>      efs_posix_user = optional(object({<br/>        # Enforces a POSIX user identity on the EFS access point. Only used when 'efs' is true.<br/>        # Security Hub: EFS.4 (EFS access points should enforce a user identity) — unset = fail; set to pass.<br/>        uid            = number<br/>        gid            = number<br/>        secondary_gids = optional(list(number))<br/>      }))<br/>    })))<br/>    port_mappings = optional(map(object({<br/>      app_protocol         = optional(string)<br/>      container_port       = number<br/>      container_port_range = optional(string)<br/>      host_port            = optional(number)<br/>      host_port_range      = optional(string)<br/>      protocol             = optional(string)<br/>      target_group_arns    = optional(list(string)) # Optional target groups ARNs to connect to this port.<br/>    })))<br/>    pseudo_terminal           = optional(bool)<br/>    read_only_root_filesystem = optional(bool) # Security Hub ECS.5 (read-only root filesystems): unset = fail; set to true to pass.<br/>    restart_policy = optional(object({<br/>      enabled                = bool<br/>      ignored_exit_codes     = optional(list(number))<br/>      restart_attempt_period = optional(number)<br/>    }))<br/>    secrets         = optional(map(string)) # Map of sensitive values to pass as environment variables. The secure storage using SSM parameters is automatically handled. Security Hub ECS.8: use this instead of 'environment' for secrets.<br/>    start_timeout   = optional(number)<br/>    stop_timeout    = optional(number)<br/>    system_controls = optional(map(string)) # Map of system controls to set. With namespace as key and value as value. The map conversion to 'namespace'/'value' key pairs is automatically handled.<br/>    ulimits = optional(map(object({<br/>      # Key is the type of the ulimit. Currently, only "nofile" is supported (Fargate limitation).<br/>      hard_limit = number<br/>      soft_limit = optional(number) # Use "hard_limit" value if not specified.<br/>    })))<br/>    user                = optional(string) # Security Hub ECS.20 (non-root user): unset = fail; set to a non-root UID/name to pass.<br/>    version_consistency = optional(bool)<br/>    working_directory   = optional(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_container_insight"></a> [container\_insight](#input\_container\_insight) | Container insight configuration. Valid values: 'enhanced', 'enabled', 'disabled'. Default to 'enabled'. Security Hub: ECS.12 (ECS clusters should use Container Insights) — default 'enabled' = pass; setting 'disabled' fails this control. | `string` | `"enabled"` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | ECS task CPU count. Valid values: 0.25, 0.5, 1, 2, 4, 8 & 16. Default of 0.25 vCPU is suitable for common use cases (text generation, embeddings). Increase for intensive workloads (multimodal requests, large LLM models). | `number` | `0.25` | no |
| <a name="input_cpu_architecture"></a> [cpu\_architecture](#input\_cpu\_architecture) | CPU architecture. Valid values: 'X86\_64' or 'ARM64'. | `string` | `"X86_64"` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | If true, enable deletion protection on eligible resources. | `bool` | `false` | no |
| <a name="input_enable_execute_command"></a> [enable\_execute\_command](#input\_enable\_execute\_command) | Whether to enable Amazon ECS Exec for the tasks within the service. | `bool` | `false` | no |
| <a name="input_ephemeral_storage_size_in_gib"></a> [ephemeral\_storage\_size\_in\_gib](#input\_ephemeral\_storage\_size\_in\_gib) | The amount of ephemeral storage to allocate for the task. This parameter is used to expand the total amount of ephemeral storage available, beyond the default amount, for tasks hosted on AWS Fargate. | `number` | `null` | no |
| <a name="input_health_check_grace_period_seconds"></a> [health\_check\_grace\_period\_seconds](#input\_health\_check\_grace\_period\_seconds) | Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 2147483647. Only valid for services configured to use load balancers. | `number` | `null` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | If specified, directly use this KMS key instead of creating a dedicated one for the application. | `string` | `null` | no |
| <a name="input_kms_policy_dependency"></a> [kms\_policy\_dependency](#input\_kms\_policy\_dependency) | To use with 'depends\_on' for resources requiring that KMS policy for key from this module is updated before creation. Only if var.kms\_key\_id is not set. | `list(any)` | `[]` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | ECS task memory (MiB). Valid values depends on the var.cpu value (x1024), see the ECS documentation for more information. Default of 512 MiB is suitable for common use cases (text generation, embeddings). Increase for intensive workloads (multimodal requests, large LLM models). | `number` | `512` | no |
| <a name="input_mount_points_backup_enable"></a> [mount\_points\_backup\_enable](#input\_mount\_points\_backup\_enable) | If 'true', enable a custom AWS Backup plan/vault for mount points, independently of var.mount\_points\_efs\_backup\_enable (EFS's native backup policy). Security Hub: EFS.2 (EFS volumes should be in backup plans) — default true = pass; setting false fails this control. | `bool` | `true` | no |
| <a name="input_mount_points_backup_retention_days"></a> [mount\_points\_backup\_retention\_days](#input\_mount\_points\_backup\_retention\_days) | Number of days to retain backups for mount points. If null, uses AWS default. | `number` | `null` | no |
| <a name="input_mount_points_efs_backup_enable"></a> [mount\_points\_efs\_backup\_enable](#input\_mount\_points\_efs\_backup\_enable) | If 'true', enable EFS automatic backups (the file system's native backup policy) for mount points, independently of var.mount\_points\_backup\_enable (the custom AWS Backup plan/vault above). Off by default since it adds cost on top of var.mount\_points\_backup\_enable, which is already enabled by default. Security Hub: EFS.7 (EFS file systems should have automatic backups enabled) — default false = fail; set to true to pass. | `bool` | `false` | no |
| <a name="input_mount_points_performance_mode"></a> [mount\_points\_performance\_mode](#input\_mount\_points\_performance\_mode) | The EFS performance mode of the EFS file system used for mount points. Valid values: 'generalPurpose' or 'maxIO'. Default to 'generalPurpose'. | `string` | `null` | no |
| <a name="input_mount_points_provisioned_throughput_in_mibps"></a> [mount\_points\_provisioned\_throughput\_in\_mibps](#input\_mount\_points\_provisioned\_throughput\_in\_mibps) | The throughput, measured in MiB/s, that you want to provision for the EFS file system used for mount points. Required only when var.mount\_points\_throughput\_mode = 'provisioned'. | `number` | `null` | no |
| <a name="input_mount_points_throughput_mode"></a> [mount\_points\_throughput\_mode](#input\_mount\_points\_throughput\_mode) | The EFS throughput mode of the EFS file system used for mount points. Valid values: 'bursting', 'provisioned', or 'elastic'. Defaults to 'bursting'. When using 'provisioned', also set var.mount\_points\_provisioned\_throughput\_in\_mibps. | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix to add to all created resources names. | `string` | `"ecs"` | no |
| <a name="input_security_group_connect_egress"></a> [security\_group\_connect\_egress](#input\_security\_group\_connect\_egress) | Add these egress rules to the ECS service security group. Also add the matching ingress rules to the source security groups, allowing them to communicate without extra configuration. | <pre>map(object({ # Key is rule description<br/>    from_port                    = number<br/>    protocol                     = optional(string, "tcp")<br/>    referenced_security_group_id = string<br/>    to_port                      = optional(number) # Default to "from_port" value<br/>  }))</pre> | `{}` | no |
| <a name="input_security_group_connect_ingress"></a> [security\_group\_connect\_ingress](#input\_security\_group\_connect\_ingress) | Add these ingress rules to the ECS service security group. Also add the matching egress rules to the source security groups, allowing them to communicate without extra configuration. Security groups reference each other here, not CIDRs, so this cannot fail EC2.13/14/53/54. | <pre>map(object({ # Key is rule description<br/>    from_port                    = number<br/>    protocol                     = optional(string, "tcp")<br/>    referenced_security_group_id = string<br/>    to_port                      = optional(number) # Default to "from_port" value<br/>  }))</pre> | `{}` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Add theses extra security group to the ECS service. | `list(string)` | `[]` | no |
| <a name="input_security_group_rules_egress"></a> [security\_group\_rules\_egress](#input\_security\_group\_rules\_egress) | Add these egress rules to the ECS service security group. | <pre>map(object({ # Key is rule description<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    from_port                    = number<br/>    prefix_list_id               = optional(string)<br/>    protocol                     = optional(string, "tcp")<br/>    referenced_security_group_id = optional(string)<br/>    to_port                      = optional(number) # Default to "from_port" value<br/>  }))</pre> | `{}` | no |
| <a name="input_security_group_rules_ingress"></a> [security\_group\_rules\_ingress](#input\_security\_group\_rules\_ingress) | Add these ingress rules to the ECS service security group. Security Hub: EC2.13/EC2.14/EC2.18/EC2.19/EC2.53/EC2.54 (security groups should not allow unrestricted/admin-port ingress from 0.0.0.0/0 or ::/0) — default {} = pass; an entry with cidr\_ipv4 = "0.0.0.0/0" or cidr\_ipv6 = "::/0" (especially covering port 22/3389) fails these controls. | <pre>map(object({ # Key is rule description<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    from_port                    = number<br/>    prefix_list_id               = optional(string)<br/>    protocol                     = optional(string, "tcp")<br/>    referenced_security_group_id = optional(string)<br/>    to_port                      = optional(number) # Default to "from_port" value<br/>  }))</pre> | `{}` | no |
| <a name="input_service_discovery_dns_health_check_failure_threshold"></a> [service\_discovery\_dns\_health\_check\_failure\_threshold](#input\_service\_discovery\_dns\_health\_check\_failure\_threshold) | Service discovery health check failure threshold. Only if var.service\_discovery\_dns\_namespace\_id is true. If null, uses AWS default. | `number` | `null` | no |
| <a name="input_service_discovery_dns_name"></a> [service\_discovery\_dns\_name](#input\_service\_discovery\_dns\_name) | If specified, use this DNS name. By default, use the resource name. Only if var.service\_discovery\_dns\_namespace\_id is specified. | `string` | `null` | no |
| <a name="input_service_discovery_dns_namespace_id"></a> [service\_discovery\_dns\_namespace\_id](#input\_service\_discovery\_dns\_namespace\_id) | If specified, enable Service discovery on the ECS service and attach it to this namespace. | `string` | `null` | no |
| <a name="input_service_discovery_dns_ttl"></a> [service\_discovery\_dns\_ttl](#input\_service\_discovery\_dns\_ttl) | Service discovery TTL for DNS entries. Only if var.service\_discovery\_dns\_namespace\_id is specified. If null, uses AWS default. | `number` | `null` | no |
| <a name="input_service_discovery_http_namespace_arn"></a> [service\_discovery\_http\_namespace\_arn](#input\_service\_discovery\_http\_namespace\_arn) | If specified, enable Service connect on the ECS service and attach it to this namespace. | `string` | `null` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | SNS topic ARN for CloudWatch alarms. If specified, CloudWatch alarms will be created for high memory usage and unhealthy containers. | `string` | `null` | no |
| <a name="input_subnets_ids"></a> [subnets\_ids](#input\_subnets\_ids) | Subnets where to deploy the service. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to created resources. Security Hub: ECS.13 (services should be tagged) and ECS.15 (task definitions should be tagged) apply this value directly with no fallback — default null fails both; ECS.14 (clusters) always passes regardless. Set tags to pass ECS.13/ECS.15. | `map(string)` | `null` | no |
| <a name="input_task_role_policies"></a> [task\_role\_policies](#input\_task\_role\_policies) | List of extra IAM policies ARNs to attach to the task role. Security Hub: attaching a policy that grants wildcard admin privileges fails IAM.1/IAM.21 — ensure attached policies follow least privilege. | `list(string)` | `[]` | no |
| <a name="input_triggers"></a> [triggers](#input\_triggers) | Map of arbitrary keys and values that, when changed, will trigger an in-place update (redeployment). | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
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