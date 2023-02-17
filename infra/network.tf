#tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "main_private" {
  for_each = var.subnets_private

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = "${var.region}${each.key}"

  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = false

  tags = {
    Name = "${var.vpc_name}_private_${each.key}"
    Type = "private"
    "kubernetes.io/role/internal-elb" : 1
  }
}

resource "aws_subnet" "main_public" {
  for_each = var.subnets_public

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = "${var.region}${each.key}"

  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = false

  tags = {
    Name = "${var.vpc_name}_public_${each.key}"
    Type = "public"
    "kubernetes.io/role/elb" : 1
  }
}

resource "aws_eip" "main" {
  for_each = var.subnets_private

  vpc = true

  tags = {
    Name = "${var.vpc_name}_${each.key}"
  }
}

resource "aws_nat_gateway" "main" {
  for_each = var.subnets_public

  allocation_id = aws_eip.main[each.key].id
  subnet_id     = aws_subnet.main_public[each.key].id

  tags = {
    Name = "${var.vpc_name}_${each.key}"
  }
}

resource "aws_route_table" "main_public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.vpc_name}_public"
  }
}

resource "aws_route_table_association" "main_public" {
  for_each = var.subnets_public

  subnet_id      = aws_subnet.main_public[each.key].id
  route_table_id = aws_route_table.main_public.id
}

resource "aws_route_table" "main_private" {
  for_each = var.subnets_private

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}_private_${each.key}"
  }
}

resource "aws_route" "main_private_nat" {
  for_each = var.subnets_private

  route_table_id         = aws_route_table.main_private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[each.key].id
  depends_on             = [aws_route_table.main_private]
}

resource "aws_route_table_association" "main_private" {
  for_each = var.subnets_private

  subnet_id      = aws_subnet.main_private[each.key].id
  route_table_id = aws_route_table.main_private[each.key].id
}

resource "aws_route53_zone" "main" {
  name = var.domain
}
