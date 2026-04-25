resource "aws_vpc_peering_connection" "peer" {
    count = var.is_peering_required ? 1 : 0
  peer_vpc_id   = data.aws_vpc.default.id  #acceptor
  vpc_id        = aws_vpc.main.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  auto_accept   = true

  tags = merge(
    var.vpc_tags,
    local.common_tags,
    {
        Name = "${local.common_suffix}-default"
    }
  )
}

# Route in VPC A (Requester) pointing to VPC B's CIDR
resource "aws_route" "public_peering" {
  count = var.is_peering_required ? 1 : 0
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block # VPC B's CIDR
  vpc_peering_connection_id = aws_vpc_peering_connection.peer[count.index].id
}

# Route in VPC B (Accepter) pointing to VPC A's CIDR
resource "aws_route" "private_peering" {
   count = var.is_peering_required ? 1 : 0
   route_table_id            = aws_route_table.private.id
   destination_cidr_block    = data.aws_vpc.default.cidr_block # VPC A's CIDR
   vpc_peering_connection_id = aws_vpc_peering_connection.peer[count.index].id
}

resource "aws_route" "default_peering" {
  count = var.is_peering_required ? 1 : 0
  route_table_id            = data.aws_route_table.main.id
  destination_cidr_block    = var.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer[count.index].id
}