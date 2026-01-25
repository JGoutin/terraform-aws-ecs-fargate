/*
Task Role: Used by the application
*/

locals {
  task_role_name = "${local.name}-task-role"
}

resource "aws_iam_role" "task_role" {
  name               = local.task_role_name
  tags               = { Name = local.task_role_name }
  assume_role_policy = data.aws_iam_policy_document.tasks_role_assume.json
}

# User specified policies

resource "aws_iam_role_policy_attachment" "task_policies" {
  count      = length(var.task_role_policies)
  role       = aws_iam_role.task_role.name
  policy_arn = var.task_role_policies[count.index]
}

# Internal policy

locals {
  task_role_policy_count = (var.enable_execute_command || local.mount_points_efs_enabled) ? 1 : 0
}

resource "aws_iam_role_policy_attachment" "task_role" {
  count      = local.task_role_policy_count
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_role[0].arn
}

resource "aws_iam_policy" "task_role" {
  count  = local.task_role_policy_count
  name   = local.task_role_name
  tags   = { Name = local.task_role_name }
  policy = data.aws_iam_policy_document.task_role[0].json
}

data "aws_iam_policy_document" "task_role" {
  count     = local.task_role_policy_count
  policy_id = "${local.name}_task_role"
  dynamic "statement" {
    for_each = toset(var.enable_execute_command ? [1] : [])
    content {
      actions = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ]
      resources = ["*"]
    }
  }
  dynamic "statement" {
    for_each = toset(var.enable_execute_command ? [1] : [])
    content {
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      resources = ["${aws_cloudwatch_log_group.execute_command[0].arn}:*"]
    }
  }
  dynamic "statement" {
    for_each = toset(var.enable_execute_command ? [1] : [])
    content {
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey",
      ]
      resources = [module.kms_key.arn]
    }
  }
  dynamic "statement" {
    for_each = toset(local.mount_points_efs_enabled ? [1] : [])
    content {
      actions = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientRootAccess",
        "elasticfilesystem:ClientWrite",
      ]
      resources = [aws_efs_file_system.mount_points[0].arn]
    }
  }
}

data "aws_iam_policy_document" "tasks_role_assume" {
  policy_id = "${local.name}_task_assume_role"
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      values   = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
      variable = "aws:SourceArn"
    }
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:SourceAccount"
    }
  }
}
