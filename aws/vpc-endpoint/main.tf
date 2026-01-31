################################################################################
# Endpoint
################################################################################

locals {
  is_interface_type = var.endpoint_service_type == "Interface"
  is_gateway_type = var.endpoint_service_type == "Gateway"
}


resource "aws_vpc_endpoint" "this" {
  # VPC ID
  vpc_id = var.vpc_id

  # VPC Endpoint Service Name
  service_name = "com.amazonaws.${var.region}.${var.endpoint_service}"

  # VPC Endpoint Type: Interface or Gateway 
  vpc_endpoint_type = try(var.endpoint_service_type, "Interface")

  # VPC Endpoints Security Group
  security_group_ids = local.is_interface_type && length(var.security_group_ids) != 0 ? var.security_group_ids : local.is_gateway_type ? null : [aws_security_group.this[0].id]

  # List of subnets where attach the VPC Endpoint (If the Endpoint Type is Gateway, this variable is not activated)
  subnet_ids = local.is_interface_type && length(var.subnet_ids) != 0 ? var.subnet_ids : []

  ## List of Route Table where attach the VPC Endpoint (If the Endpoint Type is Interface, this variable is not activated)
  route_table_ids = local.is_gateway_type && length(var.route_table_ids) != 0 ? var.route_table_ids : null
  policy          = null

  # Optional: Subnet Configuration
  dynamic "subnet_configuration" {
    for_each = try(var.subnet_configurations, [])

    content {
      ipv4      = try(subnet_configuration.value.ipv4, null)
      ipv6      = try(subnet_configuration.value.ipv6, null)
      subnet_id = try(subnet_configuration.value.subnet_id, null)
    }
  }

  # Optional: Private DNS Enabled
  private_dns_enabled = local.is_interface_type && var.private_dns_enabled
  
  # Optional: DNS Options
  dynamic "dns_options" {
    for_each = local.is_interface_type ? var.dns_options_list : []

    content {
      dns_record_ip_type                             = try(dns_options.value.dns_record_ip_type, null)
      private_dns_only_for_inbound_resolver_endpoint = try(dns_options.value.private_dns_only_for_inbound_resolver_endpoint, null)
    }
  }

  tags = merge(var.tags, { Name = var.name })

}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "this" {
  count = var.endpoint_service_type == "Interface" && length(var.security_group_ids) == 0 ? 1 : 0

  name        = "default-sg-${var.name}"
  description = "Default security group of the VPC Endpoint"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    create_before_destroy = true
  }

  depends_on = []
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  count = var.endpoint_service_type == "Interface" && length(var.security_group_ids) == 0 ? 1 : 0
  
  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
