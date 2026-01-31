# filepath: /Users/huynguyen/lab/terraform/aws/modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = var.vpc_name })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = var.internet_gateway_name })
}

# --- Public Subnets & Routing ---
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(var.availability_zones, count.index % length(var.availability_zones)) # Cycle through AZs
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "${var.public_subnet_name_prefix}-${element(var.availability_zones, count.index % length(var.availability_zones))}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.tags,
    { Name = var.public_route_table_name }
  )
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- NAT Gateway & Elastic IPs (Conditional) ---
# One EIP per NAT Gateway. Create #AZ EIPs if multi-nat, 1 if single-nat. Only if NAT enabled.
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  domain = "vpc" # Use domain instead of depends_on for IGW dependency
  tags   = merge(var.tags, { Name = "${var.elastic_ip_name_prefix}-${var.single_nat_gateway ? "single" : element(var.availability_zones, count.index)}" })
}

# One NAT Gateway per AZ unless single_nat_gateway is true. Only if NAT enabled.
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  allocation_id = aws_eip.nat[count.index].id
  # Place NAT GW in the public subnet of the corresponding AZ (or the first one if single_nat)
  subnet_id = aws_subnet.public[count.index].id

  tags = merge(var.tags, { Name = "${var.nat_gateway_name_prefix}-${var.single_nat_gateway ? "single" : element(var.availability_zones, count.index)}" })

  depends_on = [aws_internet_gateway.main] # Explicit dependency
}

# --- Private Subnets & Routing ---
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zones, count.index % length(var.availability_zones)) # Cycle through AZs
  tags              = merge(var.tags, { Name = "${var.private_subnet_name_prefix}-${element(var.availability_zones, count.index % length(var.availability_zones))}" })
}

# One private route table per AZ unless single_nat_gateway is true.
resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 1 # Create at least one RT even if no NAT
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.private_route_table_name_prefix}-${var.enable_nat_gateway ? (var.single_nat_gateway ? "single" : element(var.availability_zones, count.index)) : "default"}" })
}

# Default route for private subnets via NAT Gateway. Only if NAT enabled.
resource "aws_route" "private_nat_gateway" {
  count                  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

# Associate private subnets with the corresponding private route table
resource "aws_route_table_association" "private" {
  count     = length(var.private_subnet_cidrs)
  subnet_id = aws_subnet.private[count.index].id
  # If single NAT/RT, associate all private subnets with the single private RT.
  # If multi NAT/RT, associate subnet with the RT in its AZ.
  # If no NAT, associate with the single default private RT.
  route_table_id = aws_route_table.private[var.enable_nat_gateway ? (var.single_nat_gateway ? 0 : count.index % length(var.availability_zones)) : 0].id
}
