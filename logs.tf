/*
Cloudwatch logs.
*/

resource "aws_cloudwatch_log_group" "service" {
  name              = "${local.name}-service"
  retention_in_days = var.cloudwatch_logs_retention_in_days
  kms_key_id        = module.kms_key.arn
  depends_on        = [module.kms_key.policy_dependency]
}

resource "aws_cloudwatch_log_group" "container" {
  for_each          = toset(nonsensitive(keys(var.container_definitions)))
  name              = "${local.name}-containers/${each.key}"
  retention_in_days = var.cloudwatch_logs_retention_in_days
  kms_key_id        = module.kms_key.arn
  depends_on        = [module.kms_key.policy_dependency]
}

resource "aws_cloudwatch_log_group" "execute_command" {
  count             = var.enable_execute_command ? 1 : 0
  name              = "${local.name}-execute-command"
  retention_in_days = var.cloudwatch_logs_retention_in_days
  kms_key_id        = module.kms_key.arn
  depends_on        = [module.kms_key.policy_dependency]
}

resource "aws_cloudwatch_log_group" "container_insight" {
  count             = var.container_insight != "disabled" ? 1 : 0
  name              = "/aws/ecs/containerinsights/${local.cluster_name}/performance"
  retention_in_days = 1
  depends_on        = [module.kms_key.policy_dependency]
}
