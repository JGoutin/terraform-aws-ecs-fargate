/*
EFS mount points
*/

locals {
  mount_points = merge([for config in values(nonsensitive(var.container_definitions)) : {
    for key, value in coalesce(config.mount_points, {}) : key => coalesce(value.efs, false)
  }]...)
  mount_points_efs         = toset([for key, efs in local.mount_points : key if efs])
  mount_points_efs_name    = "${local.name}_mount_points"
  mount_points_efs_enabled = length(local.mount_points_efs) > 0
  mount_points_efs_count   = local.mount_points_efs_enabled ? 1 : 0
}

resource "aws_efs_file_system" "mount_points" {
  count            = local.mount_points_efs_count
  encrypted        = "true"
  kms_key_id       = module.kms_key.arn
  tags             = { "Name" = local.mount_points_efs_name }
  performance_mode = var.mount_points_performance_mode
  throughput_mode  = var.mount_points_throughput_mode
  provisioned_throughput_in_mibps = (
    var.mount_points_throughput_mode == "provisioned" ?
    var.mount_points_provisioned_throughput_in_mibps : null
  )
  lifecycle_policy {
    transition_to_ia                    = "AFTER_30_DAYS"
  }
  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }
}

resource "aws_efs_access_point" "mount_points" {
  for_each       = local.mount_points_efs
  file_system_id = aws_efs_file_system.mount_points[0].id
  tags           = { "Name" = "${local.mount_points_efs_name}-${each.key}" }
  root_directory {
    path = "/${each.key}"
    creation_info {
      permissions = "777"
      owner_gid   = 0
      owner_uid   = 0
    }
  }
}

resource "aws_efs_mount_target" "mount_points" {
  count           = local.mount_points_efs_enabled ? length(var.subnets_ids) : 0
  file_system_id  = aws_efs_file_system.mount_points[0].id
  subnet_id       = var.subnets_ids[count.index]
  security_groups = [aws_security_group.mount_points[0].id]
}

resource "aws_security_group" "mount_points" {
  count       = local.mount_points_efs_count
  name        = local.mount_points_efs_name
  description = local.mount_points_efs_name
  vpc_id      = local.vpc_id
  tags        = { "Name" = local.mount_points_efs_name }
}

resource "aws_vpc_security_group_ingress_rule" "mount_points" {
  count                        = local.mount_points_efs_count
  description                  = "NFS from ${local.name} ECS service"
  security_group_id            = aws_security_group.mount_points[0].id
  referenced_security_group_id = aws_security_group.main.id
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
}

resource "aws_vpc_security_group_egress_rule" "mount_points" {
  count                        = local.mount_points_efs_count
  description                  = "NFS to ${local.mount_points_efs_name} EFS file system"
  security_group_id            = aws_security_group.main.id
  referenced_security_group_id = aws_security_group.mount_points[0].id
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
}

# AWS Backup Configuration
data "aws_iam_policy_document" "backup_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_backup_vault" "mount_points" {
  count         = local.mount_points_efs_enabled && var.mount_points_backup_enable ? 1 : 0
  name          = local.mount_points_efs_name
  kms_key_arn   = module.kms_key.arn
  force_destroy = !var.deletion_protection
  tags          = { "Name" = local.mount_points_efs_name }
}

resource "aws_backup_plan" "mount_points" {
  count = local.mount_points_efs_enabled && var.mount_points_backup_enable ? 1 : 0
  name  = local.mount_points_efs_name

  rule {
    rule_name                = "hourly_backup"
    target_vault_name        = aws_backup_vault.mount_points[0].name
    schedule                 = "cron(0 * ? * * *)" # Every hour

    dynamic "lifecycle" {
      for_each = var.mount_points_backup_retention_days != null ? [1] : []
      content {
        delete_after = var.mount_points_backup_retention_days
      }
    }
  }

  tags = { "Name" = local.mount_points_efs_name }
}

resource "aws_backup_selection" "mount_points" {
  count        = local.mount_points_efs_enabled && var.mount_points_backup_enable ? 1 : 0
  name         = local.mount_points_efs_name
  iam_role_arn = aws_iam_role.backup_role[0].arn
  plan_id      = aws_backup_plan.mount_points[0].id

  resources = [
    aws_efs_file_system.mount_points[0].arn
  ]
}

resource "aws_iam_role" "backup_role" {
  count              = local.mount_points_efs_enabled && var.mount_points_backup_enable ? 1 : 0
  name               = "${local.mount_points_efs_name}-backup"
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json
  tags               = { "Name" = "${local.mount_points_efs_name}-backup" }
}

resource "aws_iam_role_policy_attachment" "backup_role" {
  count      = local.mount_points_efs_enabled && var.mount_points_backup_enable ? 1 : 0
  role       = aws_iam_role.backup_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore_role" {
  count      = local.mount_points_efs_enabled && var.mount_points_backup_enable ? 1 : 0
  role       = aws_iam_role.backup_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}
