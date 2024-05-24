resource "aws_vpc" "pjct-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = tomap({
    "Name" = "pjct-eks-node",
    "kubernetes.io/cluster/${var.cluster-name}" = "shared",
  })
}

resource "aws_subnet" "pjct-public-subnet" {
  count = 3

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.pjct-vpc.id

  tags = tomap({
    "Name" = "pjct-eks-public-node",
    "kubernetes.io/cluster/${var.cluster-name}" = "shared",
  })
}

resource "aws_subnet" "pjct-private-subnet" {
  count = 3

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.0.${count.index + 3}.0/24"
  vpc_id            = aws_vpc.pjct-vpc.id

  tags = tomap({
    "Name" = "pjct-eks-private-node",
    "kubernetes.io/cluster/${var.cluster-name}" = "shared",
  })
}

resource "aws_internet_gateway" "pjct-vpc" {
  vpc_id = aws_vpc.pjct-vpc.id

  tags = {
    Name = "pjct-vpc"
  }
}

resource "aws_route_table" "pjct-public-rt" {
  vpc_id = aws_vpc.pjct-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pjct-vpc.id
  }

  tags = {
    Name = "pjct-public-rt"
  }
}

resource "aws_route_table_association" "pjct-public-rt-assoc" {
  count = 3

  subnet_id      = aws_subnet.pjct-public-subnet[count.index].id
  route_table_id = aws_route_table.pjct-public-rt.id
}

resource "aws_route_table" "pjct-private-rt" {
  count = 3
  vpc_id = aws_vpc.pjct-vpc.id

  tags = {
    Name = "pjct-private-rt-${count.index}"
  }
}

resource "aws_route_table_association" "pjct-private-rt-assoc" {
  count = 3

  subnet_id      = aws_subnet.pjct-private-subnet[count.index].id
  route_table_id = aws_route_table.pjct-private-rt[count.index].id
}

#resource "aws_eip" "nat-gateway-eip" {
#  count  = 3
#  domain = "vpc"
#}
#
#resource "aws_nat_gateway" "nat-gateway" {
#  count = 3
#
#  allocation_id = aws_eip.nat-gateway-eip[count.index].id
#  subnet_id     = aws_subnet.pjct-public-subnet[count.index].id
#
#  tags = {
#    Name = "nat-gateway-${count.index}"
#  }
#}
#
#resource "aws_route" "nat-gateway-route" {
#  count = 3
#
#  route_table_id         = aws_route_table.pjct-private-rt[count.index].id
#  destination_cidr_block = "0.0.0.0/0"
#  nat_gateway_id         = aws_nat_gateway.nat-gateway[count.index].id
#}
