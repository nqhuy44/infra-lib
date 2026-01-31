resource "aws_security_group" "this" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id

  # Process ingress rules using dynamic blocks
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = lookup(ingress.value, "description", null)
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      # Handle potential conflicts: only one source type per rule
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
      ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", null)
      prefix_list_ids  = lookup(ingress.value, "prefix_list_ids", null)
      security_groups  = lookup(ingress.value, "security_group_id", null) != null ? [ingress.value.security_group_id] : null
      self             = lookup(ingress.value, "self", null)
    }
  }

  # Process egress rules using dynamic blocks
  dynamic "egress" {
    for_each = var.egress_rules
    content {
      description = lookup(egress.value, "description", null)
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      # Handle potential conflicts: only one destination type per rule
      cidr_blocks      = lookup(egress.value, "cidr_blocks", null)
      ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", null)
      prefix_list_ids  = lookup(egress.value, "prefix_list_ids", null)
      security_groups  = lookup(egress.value, "security_group_id", null) != null ? [egress.value.security_group_id] : null
      self             = lookup(egress.value, "self", null)
    }
  }

  tags = merge(var.tags, {
    # Set Name tag based on whether name or name_prefix is used
    Name = var.name
  })

  # Prevent destruction of default SG rules when Terraform manages rules exclusively
  # Useful if you define ALL rules via Terraform and don't want implicit rules removed/re-added on updates.
  lifecycle {
    create_before_destroy = true
  }
}
