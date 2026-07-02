/*
Service discovery: Interconnect ECS services without load balancer
*/

locals {
  service_registries_enabled = var.service_discovery_dns_namespace_id != null
  service_connect_enabled    = var.service_discovery_http_namespace_arn != null
}

resource "aws_service_discovery_service" "main" {
  count = local.service_registries_enabled ? 1 : 0
  name  = var.service_discovery_dns_name != null ? var.service_discovery_dns_name : local.name
  tags  = var.tags
  dns_config {
    namespace_id   = var.service_discovery_dns_namespace_id
    routing_policy = "MULTIVALUE"
    dns_records {
      ttl  = coalesce(var.service_discovery_dns_ttl, 60)
      type = "SRV"
    }
    dns_records {
      ttl  = coalesce(var.service_discovery_dns_ttl, 60)
      type = "A"
    }
    dynamic "dns_records" {
      for_each = toset(data.aws_subnet.current[0].ipv6_cidr_block != null ? [1] : [])
      content {
        ttl  = coalesce(var.service_discovery_dns_ttl, 60)
        type = "AAAA"
      }
    }
  }
  dynamic "health_check_custom_config" {
    for_each = var.service_discovery_dns_health_check_failure_threshold != null ? [1] : []
    content {
      failure_threshold = var.service_discovery_dns_health_check_failure_threshold
    }
  }
}
