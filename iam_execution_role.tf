/*
Execution role: Used by ECS to manage the service
*/

locals {
  execution_role_name = "${local.name}-execution-role"
}

resource "aws_iam_role" "execution_role" {
  name               = local.execution_role_name
  tags               = merge(local.tags, { Name = local.execution_role_name })
  assume_role_policy = data.aws_iam_policy_document.tasks_role_assume.json
}

resource "aws_iam_policy" "execution_role" {
  name   = local.execution_role_name
  tags   = merge(local.tags, { Name = local.execution_role_name })
  policy = data.aws_iam_policy_document.execution_role.json
}

resource "aws_iam_role_policy_attachment" "execution_role" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.execution_role.arn
}

data "aws_iam_policy_document" "execution_role" {
  policy_id = local.execution_role_name
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = [
      for repository in [
        for url in toset([
          for definition in values(var.container_definitions) :
          nonsensitive(split("@", split(":", definition.image)[0])[0])
        ]) :
        {
          account = split(".", url)[0]
          region  = split(".", url)[3]
          name    = join("/", slice(split("/", url), 1, length(split("/", url))))
        } if strcontains(url, "dkr.ecr")
      ] : "arn:aws:ecr:${repository.region}:${repository.account}:repository/${repository.name}"
    ]
  }
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = concat(
      ["${aws_cloudwatch_log_group.service.arn}:*"],
      [for log_group in aws_cloudwatch_log_group.container : "${log_group.arn}:*"],
    )
  }
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [module.kms_key.arn]
    /*condition {
      test     = "StringEquals"
      values   = ["logs.${data.aws_region.current.name}.amazonaws.com"]
      variable = "kms:ViaService"
    }*/
  }
  statement {
    # Fargate encryption & Parameter store
    actions = [
      "kms:Decrypt",
      "kms:Describe",
    ]
    resources = [module.kms_key.arn]
  }
  dynamic "statement" {
    for_each = toset(local.secrets_enabled ? [1] : [])
    content {
      actions = ["ssm:GetParameters"]
      resources = concat(
        local.secrets_enabled ? [for secret in aws_ssm_parameter.main : secret.arn] : [],
      )
    }
  }
}

data "aws_iam_policy_document" "execution_kms_policy" {
  statement {
    sid = "Allow ECS logs"
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [module.kms_key.arn]
    /*
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.name}-*"]
    }
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:SourceAccount"
    }
    */
  }
  statement {
    sid = "Allow Fargate to generate data key"
    principals {
      type        = "Service"
      identifiers = ["fargate.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKeyWithoutPlaintext"]
    resources = [module.kms_key.arn]
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:ecs:clusterAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:ecs:clusterName"
      values   = [local.cluster_name]
    }
  }
  statement {
    sid = "Allow Fargate to create grant"
    principals {
      type        = "Service"
      identifiers = ["fargate.amazonaws.com"]
    }
    actions   = ["kms:CreateGrant"]
    resources = [module.kms_key.arn]
    condition {
      test     = "ForAllValues:StringEquals"
      values   = ["Decrypt"]
      variable = "kms:GrantOperations"
    }
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:ecs:clusterAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:ecs:clusterName"
      values   = [local.cluster_name]
    }
  }
}
