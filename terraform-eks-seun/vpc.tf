# Create VPC
resource "aws_vpc" "pjct-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = tomap({
    "Name" = "pjct-eks-node",
    "kubernetes.io/cluster/${var.cluster-name}" = "shared",
  })
}

# Create public subnets
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

# Create private subnets
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

# Create Internet Gateway
resource "aws_internet_gateway" "pjct-vpc" {
  vpc_id = aws_vpc.pjct-vpc.id

  tags = {
    Name = "pjct-vpc"
  }
}

# Create "route table" [plan it for public subnets] with a "route" to the internet gateway
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

# Create Elastic IP for the NAT Gateway
resource "aws_eip" "nat-gateway-eip" {
  domain = "vpc"
}

# Create NAT Gateway, allocate the elastic IP to it, Place the NAT in the first public subnet
resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.nat-gateway-eip.id
  subnet_id     = aws_subnet.pjct-public-subnet[0].id

  tags = {
    Name = "nat-gateway"
  }
}

# Create a "route table" [plan it for private subnets] with a "route" to the NAT Gateway
resource "aws_route_table" "pjct-private-rt" {
  vpc_id = aws_vpc.pjct-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.nat-gateway.id
  }

  tags = {
    Name = "pjct-private-rt"
  }
}

# Associate the public route table with public subnets
resource "aws_route_table_association" "pjct-public-rt-assoc" {
  count = 3

  subnet_id      = aws_subnet.pjct-public-subnet[count.index].id
  route_table_id = aws_route_table.pjct-public-rt.id
}

# Associate the private route table with each private subnet.
resource "aws_route_table_association" "pjct-private-rt-assoc" {
  count = 3

  subnet_id      = aws_subnet.pjct-private-subnet[count.index].id
  route_table_id = aws_route_table.pjct-private-rt.id
}
