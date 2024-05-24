# My VPC 

This `vpc.tf` file is a Terraform script used to define and provision the networking infrastructure for an AWS Virtual Private Cloud (VPC). It includes resources for the VPC, subnets, internet gateway, route tables, and NAT gateways. Below is a detailed explanation of each resource and how they work together:

## VPC Definition
```hcl
resource "aws_vpc" "pjct-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = tomap({
    "Name" = "pjct-eks-node",
    "kubernetes.io/cluster/${var.cluster-name}" = "shared",
  })
}
```
- **aws_vpc**: This resource creates a VPC with a CIDR block of `10.0.0.0/16`.
- **cidr_block**: Specifies the IP range for the VPC.
- **tags**: Tags the VPC for identification and integration with Kubernetes using the cluster name provided by the variable `${var.cluster-name}`.

### Subnets
#### Public Subnets
```hcl
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
```
- **aws_subnet**: Creates public subnets in the VPC.
- **count**: Creates 3 subnets, one in each availability zone.
- **availability_zone**: Specifies the availability zone for each subnet.
- **cidr_block**: Defines the IP range for each subnet (e.g., `10.0.0.0/24`, `10.0.1.0/24`, `10.0.2.0/24`).
- **map_public_ip_on_launch**: Automatically assigns public IP addresses to instances launched in these subnets.
- **vpc_id**: Associates the subnet with the VPC.
- **tags**: Tags the subnets for identification.

#### Private Subnets
```hcl
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
```
- **aws_subnet**: Creates private subnets.
- **cidr_block**: Defines the IP range for each private subnet (e.g., `10.0.3.0/24`, `10.0.4.0/24`, `10.0.5.0/24`).

### Internet Gateway
```hcl
resource "aws_internet_gateway" "pjct-vpc" {
  vpc_id = aws_vpc.pjct-vpc.id

  tags = {
    Name = "pjct-vpc"
  }
}
```
- **aws_internet_gateway**: Creates an Internet Gateway to allow internet access for the public subnets.
- **vpc_id**: Associates the Internet Gateway with the VPC.

### Route Tables
#### Public Route Table
```hcl
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
```
- **aws_route_table**: Creates a route table for the public subnets.
- **route**: Adds a route to send all traffic (`0.0.0.0/0`) to the Internet Gateway.

#### Private Route Table
```hcl
resource "aws_route_table" "pjct-private-rt" {
  count = 3
  vpc_id = aws_vpc.pjct-vpc.id

  tags = {
    Name = "pjct-private-rt-${count.index}"
  }
}
```
- **aws_route_table**: Creates route tables for the private subnets (one per subnet).

### Route Table Associations
#### Public Route Table Associations
```hcl
resource "aws_route_table_association" "pjct-public-rt-assoc" {
  count = 3

  subnet_id      = aws_subnet.pjct-public-subnet[count.index].id
  route_table_id = aws_route_table.pjct-public-rt.id
}
```
- **aws_route_table_association**: Associates the public subnets with the public route table.

#### Private Route Table Associations
```hcl
resource "aws_route_table_association" "pjct-private-rt-assoc" {
  count = 3

  subnet_id      = aws_subnet.pjct-private-subnet[count.index].id
  route_table_id = aws_route_table.pjct-private-rt[count.index].id
}
```
- **aws_route_table_association**: Associates the private subnets with their respective private route tables.

### NAT Gateways
#### Elastic IPs for NAT Gateways
```hcl
resource "aws_eip" "nat-gateway-eip" {
  count  = 3
  domain = "vpc"
}
```
- **aws_eip**: Allocates Elastic IPs for the NAT Gateways.

#### NAT Gateways
```hcl
resource "aws_nat_gateway" "nat-gateway" {
  count = 3

  allocation_id = aws_eip.nat-gateway-eip[count.index].id
  subnet_id     = aws_subnet.pjct-public-subnet[count.index].id

  tags = {
    Name = "nat-gateway-${count.index}"
  }
}
```
- **aws_nat_gateway**: Creates NAT Gateways in the public subnets to allow instances in the private subnets to access the internet.

#### Routes for NAT Gateways
```hcl
resource "aws_route" "nat-gateway-route" {
  count = 3

  route_table_id         = aws_route_table.pjct-private-rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gateway[count.index].id
}
```
- **aws_route**: Adds routes to the private route tables to route all internet-bound traffic through the NAT Gateways.

### Summary
This Terraform script sets up a VPC with both public and private subnets across three availability zones. It creates an internet gateway for the public subnets and NAT gateways for internet access from the private subnets. Route tables and associations ensure proper routing between these components. The setup is tagged for integration with an EKS cluster, enabling Kubernetes to manage resources within this infrastructure.
