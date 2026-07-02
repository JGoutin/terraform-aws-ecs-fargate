/*
Secrets environment variables stored securely using SSM parameters.
*/

locals {
  secrets = nonsensitive(merge([
    for container_name, container_config in nonsensitive(var.container_definitions) :
    {
      for secret_name, secret_value in coalesce(container_config.secrets, {}) :
      "${container_name}-${secret_name}" => tostring(secret_value)
    }
  ]...))
  secrets_enabled = length(local.secrets) > 0
}

resource "aws_ssm_parameter" "main" {
  for_each = local.secrets
  name     = "${local.name}-container-${each.key}"
  value    = each.value
  key_id   = module.kms_key.id
  type     = "SecureString"
  tier     = "Intelligent-Tiering"
  tags     = var.tags
}
