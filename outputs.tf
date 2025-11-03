output "security_group_id" {
  description = "ECS service security group ID"
  value       = coalesce(aws_security_group.main.id)
}

output "service_discovery_service_name" {
  description = "Service discovery service name. Only if var.service_discovery_dns_namespace_id is defined."
  value       = local.service_registries_enabled ? coalesce(aws_service_discovery_service.main[0].name) : null
}

output "kms_policy_documents_json" {
  description = "KMS policy documents to add to the policy of the key specified via var.kms_key_id."
  value       = module.kms_key.policy_documents_json
}

output "kms_policy_dependency" {
  description = "To use with 'depends_on' for resources requiring that KMS policy is updated before creation. Only if var.kms_key_id is set."
  value       = module.kms_key.policy_dependency
}

output "kms_key_id" {
  description = "KMS key ID."
  value       = module.kms_key.id
}

output "kms_key_arn" {
  description = "KMS key ARN."
  value       = module.kms_key.arn
}

output "cloudwatch_log_groups_names" {
  description = "Log group names for each containers."
  value       = { for name, log_group in aws_cloudwatch_log_group.container : name => log_group.name }
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.main.name
}