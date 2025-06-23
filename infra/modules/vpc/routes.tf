resource "aws_route_table" "main" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = var.cidr_block
    gateway_id = "local"
  }

  tags = merge(var.tags, {
    Name = "${var.vpc_name}_main_rt"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = join("_", [var.vpc_name, "public_rt"])
  })
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = join("_", [var.vpc_name, "private_rt", index(var.private_subnets, each.key) + 1])
  })
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route" "private" {
  for_each = aws_subnet.private

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[element(var.public_subnets, index(var.private_subnets, each.key) % min(length(var.public_subnets), length(var.private_subnets), length(data.aws_availability_zones.available.names)))].id
}

resource "aws_main_route_table_association" "this" {
  vpc_id         = aws_vpc.this.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}