/*
Configuration
*/

locals {
  # Resources names
  name = "${var.name_prefix}-${data.aws_region.current.name}"

  # Tags to merge into resources that already carry a Name tag
  tags = coalesce(var.tags, {})

  # Port mapping for load balancer & service discovery attachment
  port_mappings = nonsensitive(tomap(merge([for container_name, definition in var.container_definitions : {
    for port_name, port_mapping in coalesce(definition.port_mappings, {}) : "${container_name}_${port_name}" => {
      container_name    = container_name
      container_port    = port_mapping.container_port
      port_name         = port_name
      target_group_arns = port_mapping.target_group_arns
    }
  }]...)))
}

/*
Common data
*/

locals {
  availability_zones = toset([for subnet in data.aws_subnet.current : subnet.availability_zone])
  vpc_id             = data.aws_subnet.current[0].vpc_id
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_subnet" "current" {
  count = length(var.subnets_ids)
  id    = var.subnets_ids[count.index]
}

/*
KMS key
*/

module "kms_key" {
  source  = "JGoutin/kms-key/aws"
  version = "~> 1.2"

  id                    = var.kms_key_id
  name_prefix           = var.name_prefix
  tags                  = local.tags
  policy_documents_json = [data.aws_iam_policy_document.execution_kms_policy.json]
  policy_dependency     = var.kms_policy_dependency
}
