resource "aws_vpc_peering_connection" "this" {
  vpc_id      = var.requester_vpc_id
  peer_vpc_id = var.accepter_vpc_id
  peer_region = var.peer_region
  auto_accept = var.auto_accept

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )

  # Optional DNS resolution settings for requester VPC
  dynamic "requester" {
    for_each = var.enable_dns_resolution ? [1] : []
    content {
      allow_remote_vpc_dns_resolution = true
    }
  }

  # Optional DNS resolution settings for accepter VPC
  dynamic "accepter" {
    for_each = var.enable_dns_resolution ? [1] : []
    content {
      allow_remote_vpc_dns_resolution = true
    }
  }
}

# Create routes in the requester VPC route tables
resource "aws_route" "requester_routes" {
  count                     = length(var.requester_route_table_ids)
  route_table_id            = var.requester_route_table_ids[count.index]
  destination_cidr_block    = var.accepter_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  depends_on                = [aws_vpc_peering_connection.this]
}

# Create routes in the accepter VPC route tables
resource "aws_route" "accepter_routes" {
  count                     = length(var.accepter_route_table_ids)
  route_table_id            = var.accepter_route_table_ids[count.index]
  destination_cidr_block    = var.requester_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  depends_on                = [aws_vpc_peering_connection.this]
}
