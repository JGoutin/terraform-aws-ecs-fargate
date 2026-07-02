variable "name_prefix" {
  description = "Prefix to add to all created resources names."
  type        = string
  default     = "ecs"
}

variable "subnets_ids" {
  description = "Subnets where to deploy the service."
  type        = list(string)
}

variable "autoscaling_min_capacity" {
  description = "Minimum capacity for autoscaling. If not specified, the subnets count in used."
  type        = number
  default     = null
}

variable "autoscaling_max_capacity" {
  description = "Maximum capacity for autoscaling. If set to the same value than var.autoscaling_min_capacity, autoscaling is disabled. If not specified, the 5 x subnets count in used."
  type        = number
  default     = null
}

variable "autoscaling_cpu_target_percent" {
  description = "Percent of CPU to use as target for autoscaling. If null, uses AWS default."
  type        = number
  default     = null
}

variable "autoscaling_memory_target_percent" {
  description = "Target memory utilization percentage for auto-scaling. If null, memory-based scaling is disabled."
  type        = number
  default     = null
}

variable "autoscaling_alb_target_requests_per_target" {
  description = "Target number of ALB requests per ECS task for auto-scaling. If null, request-based scaling is disabled."
  type        = number
  default     = null
}

variable "autoscaling_alb_resource_label" {
  description = "ALB resource label for request-based scaling (format: app/load-balancer-name/xxx/targetgroup/target-group-name/yyy). Required if autoscaling_alb_target_requests_per_target is set."
  type        = string
  default     = null
}

variable "autoscaling_scale_in_cooldown" {
  description = "Time in seconds after a scale-in activity completes before another scale-in can start. If null, uses AWS default."
  type        = number
  default     = null
}

variable "autoscaling_scale_out_cooldown" {
  description = "Time in seconds after a scale-out activity completes before another scale-out can start. If null, uses AWS default."
  type        = number
  default     = null
}

variable "autoscaling_schedule_stop" {
  description = "If Specified, schedule service stop/pause (By scaling to 0). The following formats are supported: At expressions - at(yyyy-mm-ddThh:mm:ss), Rate expressions - rate(valueunit), Cron expressions - cron(fields). In UTC."
  type        = string
  default     = null
}

variable "autoscaling_schedule_start" {
  description = "If Specified, schedule service start if paused by var.autoscaling_schedule_pause_cron_expression. The following formats are supported: At expressions - at(yyyy-mm-ddThh:mm:ss), Rate expressions - rate(valueunit), Cron expressions - cron(fields). In UTC"
  type        = string
  default     = null
}

variable "mount_points_performance_mode" {
  description = "The EFS performance mode of the EFS file system used for mount points. Valid values: 'generalPurpose' or 'maxIO'. Default to 'generalPurpose'."
  type        = string
  default     = null
}

variable "autoscaling_spot_percent" {
  description = "Percent of capacity over the minimum capacity to run with Fargate Spot."
  type        = number
  default     = 0
}

variable "autoscaling_spot_on_demand_min_capacity" {
  description = "Minimum of on-demand capacity when var.autoscaling_spot_percent is enabled. If not specified, same as the var.autoscaling_min_capacity value."
  type        = number
  default     = null
}

variable "mount_points_throughput_mode" {
  description = "The EFS throughput mode of the EFS file system used for mount points. Valid values: 'bursting', 'provisioned', or 'elastic'. Defaults to 'bursting'. When using 'provisioned', also set var.mount_points_provisioned_throughput_in_mibps."
  type        = string
  default     = null
}

variable "mount_points_provisioned_throughput_in_mibps" {
  description = "The throughput, measured in MiB/s, that you want to provision for the EFS file system used for mount points. Required only when var.mount_points_throughput_mode = 'provisioned'."
  type        = number
  default     = null
}

variable "mount_points_backup_enable" {
  description = "If 'true', enable a custom AWS Backup plan/vault for mount points, independently of var.mount_points_efs_backup_enable (EFS's native backup policy). Security Hub: EFS.2 (EFS volumes should be in backup plans) — default true = pass; setting false fails this control."
  type        = bool
  default     = true
}

variable "mount_points_efs_backup_enable" {
  description = "If 'true', enable EFS automatic backups (the file system's native backup policy) for mount points, independently of var.mount_points_backup_enable (the custom AWS Backup plan/vault above). Off by default since it adds cost on top of var.mount_points_backup_enable, which is already enabled by default. Security Hub: EFS.7 (EFS file systems should have automatic backups enabled) — default false = fail; set to true to pass."
  type        = bool
  default     = false
}

variable "mount_points_backup_retention_days" {
  description = "Number of days to retain backups for mount points. If null, uses AWS default."
  type        = number
  default     = null
}

variable "container_insight" {
  description = "Container insight configuration. Valid values: 'enhanced', 'enabled', 'disabled'. Default to 'enabled'. Security Hub: ECS.12 (ECS clusters should use Container Insights) — default 'enabled' = pass; setting 'disabled' fails this control."
  type        = string
  default     = "enabled"
}

variable "cloudwatch_logs_retention_in_days" {
  description = "Cloudwatch logs retention in days. Applies to every log group this module creates (service, per-container, execute-command, and Container Insights performance). Security Hub: CloudWatch.16 (CloudWatch log groups should be retained for a specified time period) requires at least 365 days by default — default 365 = pass; lowering it fails this control."
  type        = number
  default     = 365
}

variable "kms_key_id" {
  description = "If specified, directly use this KMS key instead of creating a dedicated one for the application."
  type        = string
  default     = null
}

variable "cpu" {
  description = "ECS task CPU count. Valid values: 0.25, 0.5, 1, 2, 4, 8 & 16. Default of 0.25 vCPU is suitable for common use cases (text generation, embeddings). Increase for intensive workloads (multimodal requests, large LLM models)."
  type        = number
  default     = 0.25
}

variable "cpu_architecture" {
  description = "CPU architecture. Valid values: 'X86_64' or 'ARM64'."
  type        = string
  default     = "X86_64"
  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "var.cpu_architecture must be 'X86_64' or 'ARM64'."
  }
}

variable "memory" {
  description = "ECS task memory (MiB). Valid values depends on the var.cpu value (x1024), see the ECS documentation for more information. Default of 512 MiB is suitable for common use cases (text generation, embeddings). Increase for intensive workloads (multimodal requests, large LLM models)."
  type        = number
  default     = 512
}

variable "container_definitions" {
  description = "ECS task containers definition. See ECS task definition parameters documentation for more information on each parameter (Convert parameter name from snake case to camel case)."
  sensitive   = true
  type = map(object({
    command       = optional(list(string))
    cpu           = optional(number)
    depends_on    = optional(map(string)) # Map of other containers of the task to depends on. With container name as key and condition as value. The map conversion to 'containerName'/'condition' key pairs is automatically handled.
    docker_labels = optional(map(string))
    entrypoint    = optional(list(string))
    essential     = optional(bool, true)
    environment   = optional(map(string)) # Map of environment variable. The map conversion to 'name'/'value' key pairs is automatically handled. null values are ignored. Security Hub ECS.8: never put secrets here, use 'secrets' below instead.
    health_check = optional(object({
      command      = list(string)
      timeout      = optional(number)
      retries      = optional(number)
      interval     = optional(number)
      start_period = optional(number)
    }))
    image       = string # Only ECR image are supported for now (ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/REPOSITORY_NAME:TAG or ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/REPOSITORY_NAME@HASH)
    interactive = optional(bool)
    linux_parameters = optional(object({
      capabilities = optional(object({
        add  = optional(list(string), [])
        drop = optional(list(string), [])
      }))
      init_process_enabled = optional(bool)
    }))
    log_configuration = optional(object({
      # Cloudwatch log groups are automatically created with "awslogs" driver. Theses parameters are options for this driver.
      blocking          = optional(bool) # If 'true', set mode to 'blocking', else to 'non-blocking', the default ECS mode.
      datetime_format   = optional(string)
      max_buffer_size   = optional(string)
      multiline_pattern = optional(string)
    }))
    memory             = optional(number)
    memory_reservation = optional(number)
    mount_points = optional(map(object({
      container_path = string
      read_only      = optional(bool)
      efs            = optional(bool) # If true, an EFS file-system is automatically created with a mount target for each specified mount point, else ephemeral storage is used.
      efs_posix_user = optional(object({
        # Enforces a POSIX user identity on the EFS access point. Only used when 'efs' is true.
        # Security Hub: EFS.4 (EFS access points should enforce a user identity) — unset = fail; set to pass.
        uid            = number
        gid            = number
        secondary_gids = optional(list(number))
      }))
    })))
    port_mappings = optional(map(object({
      app_protocol         = optional(string)
      container_port       = number
      container_port_range = optional(string)
      host_port            = optional(number)
      host_port_range      = optional(string)
      protocol             = optional(string)
      target_group_arns    = optional(list(string)) # Optional target groups ARNs to connect to this port.
    })))
    pseudo_terminal           = optional(bool)
    read_only_root_filesystem = optional(bool) # Security Hub ECS.5 (read-only root filesystems): unset = fail; set to true to pass.
    restart_policy = optional(object({
      enabled                = bool
      ignored_exit_codes     = optional(list(number))
      restart_attempt_period = optional(number)
    }))
    secrets         = optional(map(string)) # Map of sensitive values to pass as environment variables. The secure storage using SSM parameters is automatically handled. Security Hub ECS.8: use this instead of 'environment' for secrets.
    start_timeout   = optional(number)
    stop_timeout    = optional(number)
    system_controls = optional(map(string)) # Map of system controls to set. With namespace as key and value as value. The map conversion to 'namespace'/'value' key pairs is automatically handled.
    ulimits = optional(map(object({
      # Key is the type of the ulimit. Currently, only "nofile" is supported (Fargate limitation).
      hard_limit = number
      soft_limit = optional(number) # Use "hard_limit" value if not specified.
    })))
    user                = optional(string) # Security Hub ECS.20 (non-root user): unset = fail; set to a non-root UID/name to pass.
    version_consistency = optional(bool)
    working_directory   = optional(string)
  }))
}

variable "ephemeral_storage_size_in_gib" {
  type        = number
  description = "The amount of ephemeral storage to allocate for the task. This parameter is used to expand the total amount of ephemeral storage available, beyond the default amount, for tasks hosted on AWS Fargate."
  default     = null
}

variable "service_discovery_dns_namespace_id" {
  type        = string
  description = "If specified, enable Service discovery on the ECS service and attach it to this namespace."
  default     = null
}

variable "service_discovery_dns_name" {
  type        = string
  description = "If specified, use this DNS name. By default, use the resource name. Only if var.service_discovery_dns_namespace_id is specified."
  default     = null
}

variable "service_discovery_dns_ttl" {
  type        = number
  description = "Service discovery TTL for DNS entries. Only if var.service_discovery_dns_namespace_id is specified. If null, uses AWS default."
  default     = null
}

variable "service_discovery_dns_health_check_failure_threshold" {
  type        = number
  description = "Service discovery health check failure threshold. Only if var.service_discovery_dns_namespace_id is true. If null, uses AWS default."
  default     = null
}

variable "alarms_enabled" {
  description = "Enable CloudWatch alarms. This should be set to true if sns_topic_arn is provided."
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms. If specified, CloudWatch alarms will be created for high memory usage and unhealthy containers."
  type        = string
  default     = null
}

variable "service_discovery_http_namespace_arn" {
  type        = string
  description = "If specified, enable Service connect on the ECS service and attach it to this namespace."
  default     = null
}

variable "triggers" {
  description = "Map of arbitrary keys and values that, when changed, will trigger an in-place update (redeployment)."
  type        = map(string)
  default     = {}
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 2147483647. Only valid for services configured to use load balancers."
  type        = number
  default     = null
}

variable "enable_execute_command" {
  type        = bool
  description = " Whether to enable Amazon ECS Exec for the tasks within the service."
  default     = false
}

variable "task_role_policies" {
  type        = list(string)
  description = "List of extra IAM policies ARNs to attach to the task role. Security Hub: attaching a policy that grants wildcard admin privileges fails IAM.1/IAM.21 — ensure attached policies follow least privilege."
  default     = []
}

variable "security_group_ids" {
  type        = list(string)
  description = "Add theses extra security group to the ECS service."
  default     = []
}

variable "security_group_connect_egress" {
  type = map(object({ # Key is rule description
    from_port                    = number
    protocol                     = optional(string, "tcp")
    referenced_security_group_id = string
    to_port                      = optional(number) # Default to "from_port" value
  }))
  description = "Add these egress rules to the ECS service security group. Also add the matching ingress rules to the source security groups, allowing them to communicate without extra configuration."
  default     = {}
}

variable "security_group_connect_ingress" {
  type = map(object({ # Key is rule description
    from_port                    = number
    protocol                     = optional(string, "tcp")
    referenced_security_group_id = string
    to_port                      = optional(number) # Default to "from_port" value
  }))
  description = "Add these ingress rules to the ECS service security group. Also add the matching egress rules to the source security groups, allowing them to communicate without extra configuration. Security groups reference each other here, not CIDRs, so this cannot fail EC2.13/14/53/54."
  default     = {}
}

variable "security_group_rules_egress" {
  description = "Add these egress rules to the ECS service security group."
  type = map(object({ # Key is rule description
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    from_port                    = number
    prefix_list_id               = optional(string)
    protocol                     = optional(string, "tcp")
    referenced_security_group_id = optional(string)
    to_port                      = optional(number) # Default to "from_port" value
  }))
  default = {}
}

variable "security_group_rules_ingress" {
  description = "Add these ingress rules to the ECS service security group. Security Hub: EC2.13/EC2.14/EC2.18/EC2.19/EC2.53/EC2.54 (security groups should not allow unrestricted/admin-port ingress from 0.0.0.0/0 or ::/0) — default {} = pass; an entry with cidr_ipv4 = \"0.0.0.0/0\" or cidr_ipv6 = \"::/0\" (especially covering port 22/3389) fails these controls."
  type = map(object({ # Key is rule description
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    from_port                    = number
    prefix_list_id               = optional(string)
    protocol                     = optional(string, "tcp")
    referenced_security_group_id = optional(string)
    to_port                      = optional(number) # Default to "from_port" value
  }))
  default = {}
}

variable "kms_policy_dependency" {
  description = "To use with 'depends_on' for resources requiring that KMS policy for key from this module is updated before creation. Only if var.kms_key_id is not set."
  type        = list(any)
  default     = []
}

variable "assign_public_ip" {
  description = "Assign a public IP address to the ENI. Security Hub: ECS.2 (ECS services should not have public IP addresses assigned to them automatically) — default null (resolves to DISABLED) = pass; setting true fails this control."
  type        = bool
  default     = null
}

# Other

variable "deletion_protection" {
  description = "If true, enable deletion protection on eligible resources."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to created resources. Security Hub: ECS.13 (services should be tagged) and ECS.15 (task definitions should be tagged) apply this value directly with no fallback — default null fails both; ECS.14 (clusters) always passes regardless. Set tags to pass ECS.13/ECS.15."
  type        = map(string)
  default     = null
}
