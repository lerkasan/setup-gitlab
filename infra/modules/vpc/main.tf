resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, {
    Name = var.vpc_name
  })
}

resource "aws_subnet" "public" {
  for_each = toset(var.public_subnets)

  vpc_id     = aws_vpc.this.id
  cidr_block = each.value

  # If we need more public subnets than availability zones, this will cycle through the AZs.
  availability_zone = data.aws_availability_zones.available.names[index(var.public_subnets, each.value) % length(data.aws_availability_zones.available.names)]

  tags = merge(var.tags, {
    Name = join("_", [var.vpc_name, "public_subnet", index(var.public_subnets, each.value) + 1])
  })
}

resource "aws_subnet" "private" {
  for_each = toset(var.private_subnets)

  vpc_id     = aws_vpc.this.id
  cidr_block = each.value

  # If we need more private subnets than availability zones, this will cycle through the AZs.
  availability_zone = data.aws_availability_zones.available.names[index(var.private_subnets, each.value) % length(data.aws_availability_zones.available.names)]

  tags = merge(var.tags, {
    Name = join("_", [var.vpc_name, "private_subnet", index(var.private_subnets, each.value) + 1])
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = join("_", [var.vpc_name, "igw"])
  })
}

resource "aws_nat_gateway" "this" {
  # Use the same number of NAT gateways as private subnets, or fewer if there are not enough public subnets or availability zones.
  for_each = toset(slice(var.public_subnets, 0, min(length(var.public_subnets), length(var.private_subnets), length(data.aws_availability_zones.available.names))))

  subnet_id     = aws_subnet.public[each.key].id
  allocation_id = aws_eip.this[each.key].id

  tags = merge(var.tags, {
    Name = join("_", [var.vpc_name, "nat_gw", index(var.public_subnets, each.value) + 1])
  })
}

resource "aws_eip" "this" {
  # Use the same number of EIPs as NAT gateways
  for_each = toset(slice(var.public_subnets, 0, min(length(var.public_subnets), length(var.private_subnets), length(data.aws_availability_zones.available.names))))

  domain = "vpc"

  tags = merge(var.tags, {
    Name = join("_", [var.vpc_name, "nat_gw_eip", index(var.public_subnets, each.value) + 1])
  })
}

resource "aws_default_security_group" "this" {
  # Ensure that the default security group restricts all inbound and outbound traffic - best practice according to Checkov
  # No rules are defined for the default security group, so it will not allow any inbound or outbound traffic by default.
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name = join("_", [var.vpc_name, "default_sg"])
  })
}