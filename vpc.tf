# provider block for AWS provider
provider "aws" {
  region = "us-east-1"
}

# create VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.1.2.0/24"
}

# create public subnet
resource "aws_subnet" "public-subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.1.2.0/26"
  tags = {
    Name = "Backstreet Boys Public Subnet"
  }
}

# create private subnet
resource "aws_subnet" "private-subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.1.2.64/26"
  tags = {
    Name = "Backstreet Boys Private Subnet"
  }
}

# create internet gateway
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id
}

# attach internet gateway to VPC
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.vpc.id
}

# create route table for public subnet
resource "aws_route_table" "public-routetable" {
  vpc_id = aws_vpc.vpc.id
}

# create route for public subnet
resource "aws_route" "public-route" {
  route_table_id = aws_route_table.public-routetable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet-gateway.id
}

# associate route table with public subnet
resource "aws_route_table_association" "public-subnet-association" {
  subnet_id = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-routetable.id
}

# create security group for web server
resource "aws_security_group" "web-securitygroup" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# create security group for database server
resource "aws_security_group" "db-securitygroup" {
  vpc_id = aws_vpc.vpc.id
  
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.web-securitygroup.id]
  }
}

# create web server instance
resource "aws_instance" "web-instance" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.web-securitygroup.id]
  tags = {
    Name = "Backstreet Boys Web Server"
  }
}

# create database server instance
resource "aws_instance" "db-instance" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private-subnet.id
  vpc_security_group_ids = [aws_security_group.db-securitygroup.id]
  tags = {
    Name = "Backstreet Boys Database Server"
  }
}

resource "aws_lb" "web-lb" {
name               = "BackstreetBoysLoadBalancer"
internal           = false
load_balancer_type = "application"

subnet_mapping {
subnet_id = aws_subnet.public-subnet.id
}

tags = {
Name = "Backstreet Boys Load Balancer"
}
}

resource "aws_lb_target_group" "web-target-group" {
name     = "BackstreetBoysWebTargetGroup"
port     = 80
protocol = "HTTP"
vpc_id   = aws_vpc.vpc.id

health_check {
path     = "/"
protocol = "HTTP"
}
}

resource "aws_lb_listener" "web-listener" {
load_balancer_arn = aws_lb.web-lb.arn
port              = 80
protocol          = "HTTP"

default_action {
target_group_arn = aws_lb_target_group.web-target-group.arn
type             = "forward"
}
}
