resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}


# Subnets 

resource "aws_subnet" "ecs_public_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    depends_on = [ aws_vpc.main ]
}

resource "aws_subnet" "ecs_public_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"
    depends_on = [ aws_vpc.main ]
}

resource "aws_subnet" "ecs_private_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.101.0/24"
    depends_on = [ aws_vpc.main ]
}

resource "aws_subnet" "ecs_private_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.102.0/24"
    depends_on = [ aws_vpc.main ]
}


# Internet Gateway

resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.main.id
  depends_on = [ aws_vpc.main ]
}

# elastic ip for Nat_gateway
resource "aws_eip" "Eip_nat" {}

# Nat_gateway for Internet access to private subnets
resource "aws_nat_gateway" "ecs_nat" {
  allocation_id = aws_eip.Eip_nat.id
  subnet_id     = aws_subnet.ecs_public_1.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.ecs_igw]
}

# route tables and routes
#public route table
resource "aws_route_table" "ecs_public_rt" {
    vpc_id = aws_vpc.main.id
}

#public route
resource "aws_route" "r_ig" {
  route_table_id = aws_route_table.ecs_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.ecs_igw.id
  depends_on = [ aws_internet_gateway.ecs_igw ]
}

#private route table 
resource "aws_route_table" "ecs_private_rt" {
  vpc_id = aws_vpc.main.id
}

#private route
resource "aws_route" "r_nat" {
  route_table_id = aws_route_table.ecs_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.ecs_nat.id
  depends_on = [ aws_nat_gateway.ecs_nat ]
}

# route Table association to subnets

#private subnets association 
resource "aws_route_table_association" "private_subnet_rta_1" {
  subnet_id      = aws_subnet.ecs_private_1.id
  route_table_id = aws_route_table.ecs_private_rt.id
}

resource "aws_route_table_association" "private_subnet_rta_2" {
  subnet_id      = aws_subnet.ecs_private_2.id
  route_table_id = aws_route_table.ecs_private_rt.id
}

#public subnets association
resource "aws_route_table_association" "public_subnet_rta_1" {
  subnet_id = aws_subnet.ecs_public_1.id
  route_table_id = aws_route_table.ecs_public_rt.id
}

resource "aws_route_table_association" "public_subnet_rta_2" {
  subnet_id = aws_subnet.ecs_public_2.id
  route_table_id = aws_route_table.ecs_public_rt.id
}
