/*
ECS service security group
*/

locals {
  security_group_name = "${local.name}-security-group"
}

resource "aws_security_group" "main" {
  name        = local.security_group_name
  description = local.security_group_name
  tags        = merge(local.tags, { "Name" = local.security_group_name })
  vpc_id      = local.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "main" {
  for_each                     = var.security_group_rules_ingress
  description                  = each.key
  security_group_id            = aws_security_group.main.id
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.referenced_security_group_id
  from_port                    = each.value.from_port
  to_port                      = coalesce(each.value.to_port, each.value.from_port)
  ip_protocol                  = each.value.protocol
  tags                         = var.tags
}

resource "aws_vpc_security_group_egress_rule" "main" {
  for_each                     = var.security_group_rules_egress
  description                  = each.key
  security_group_id            = aws_security_group.main.id
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.referenced_security_group_id
  from_port                    = each.value.from_port
  to_port                      = coalesce(each.value.to_port, each.value.from_port)
  ip_protocol                  = each.value.protocol
  tags                         = var.tags
}

/*
Connect with other security groups: egress
*/

resource "aws_vpc_security_group_egress_rule" "connect_egress" {
  for_each                     = var.security_group_connect_egress
  description                  = each.key
  security_group_id            = aws_security_group.main.id
  referenced_security_group_id = each.value.referenced_security_group_id
  from_port                    = each.value.from_port
  to_port                      = coalesce(each.value.to_port, each.value.from_port)
  ip_protocol                  = each.value.protocol
  tags                         = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "connect_egress" {
  for_each                     = var.security_group_connect_egress
  description                  = each.key
  security_group_id            = each.value.referenced_security_group_id
  referenced_security_group_id = aws_security_group.main.id
  from_port                    = each.value.from_port
  to_port                      = coalesce(each.value.to_port, each.value.from_port)
  ip_protocol                  = each.value.protocol
  tags                         = var.tags
}

/*
Connect with other security groups: ingress
*/

resource "aws_vpc_security_group_ingress_rule" "connect_ingress" {
  for_each                     = var.security_group_connect_ingress
  description                  = each.key
  security_group_id            = aws_security_group.main.id
  referenced_security_group_id = each.value.referenced_security_group_id
  from_port                    = each.value.from_port
  to_port                      = coalesce(each.value.to_port, each.value.from_port)
  ip_protocol                  = each.value.protocol
  tags                         = var.tags
}

resource "aws_vpc_security_group_egress_rule" "connect_ingress" {
  for_each                     = var.security_group_connect_ingress
  description                  = each.key
  security_group_id            = each.value.referenced_security_group_id
  referenced_security_group_id = aws_security_group.main.id
  from_port                    = each.value.from_port
  to_port                      = coalesce(each.value.to_port, each.value.from_port)
  ip_protocol                  = each.value.protocol
  tags                         = var.tags
}
