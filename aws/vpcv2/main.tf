# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, {
    Name = var.vpc_name
  })
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-igw"
  })
}

# --- Custom Subnets ---
resource "aws_subnet" "main" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.type == "public" ? true : each.value.map_public_ip_on_launch

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.key
      Type = each.value.type
    }
  )
}

# --- Elastic IPs for NAT Gateways ---
resource "aws_eip" "nat" {
  for_each = var.nat_gateways

  domain = "vpc"

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = "${each.key}-eip"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# --- NAT Gateways ---
resource "aws_nat_gateway" "main" {
  for_each = var.nat_gateways

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.main[each.value.public_subnet_key].id

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.key
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# --- Route Tables ---
resource "aws_route_table" "main" {
  for_each = var.route_tables

  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.key
      Type = each.value.type
    }
  )
}

# --- Internet Gateway Routes (for public route tables) ---
resource "aws_route" "internet_gateway" {
  for_each = {
    for k, v in var.route_tables : k => v if v.type == "public"
  }

  route_table_id         = aws_route_table.main[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# --- NAT Gateway Routes (for private route tables) ---
resource "aws_route" "nat_gateway" {
  for_each = {
    for k, v in var.route_tables : k => v
    if v.type == "private" && v.nat_gateway_key != null
  }

  route_table_id         = aws_route_table.main[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[each.value.nat_gateway_key].id
}

# --- Custom Routes ---
# resource "aws_route" "custom" {
#   for_each = merge([
#     for rt_key, rt_config in var.route_tables : {
#       for route_idx, route in rt_config.routes : "${rt_key}-${route_idx}" => {
#         route_table_id            = aws_route_table.main[rt_key].id
#         destination_cidr_block    = route.destination_cidr_block
#         gateway_id                = route.gateway_id
#         nat_gateway_id            = route.nat_gateway_id != null ? aws_nat_gateway.main[route.nat_gateway_id].id : null
#         instance_id               = route.instance_id
#         vpc_peering_connection_id = route.vpc_peering_connection_id
#       }
#     }
#   ]...)

#   route_table_id            = each.value.route_table_id
#   destination_cidr_block    = each.value.destination_cidr_block
#   gateway_id                = each.value.gateway_id
#   nat_gateway_id            = each.value.nat_gateway_id
#   instance_id               = each.value.instance_id
#   vpc_peering_connection_id = each.value.vpc_peering_connection_id
# }

# --- Route Table Associations ---
resource "aws_route_table_association" "main" {
  for_each = var.subnet_route_table_associations

  subnet_id      = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.main[each.value].id
}