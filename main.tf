provider "aws" {
  region = var.region
}

# Upload public key to AWS as Key Pair
resource "aws_key_pair" "shubham" {
  key_name   = var.key_name
  public_key = file("home/ubuntu/.ssh/shubham.pub")
}

# VPC
resource "aws_vpc" "sandbox_vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "sandbox-vpc" }
}

# Subnet
resource "aws_subnet" "sandbox_subnet" {
  vpc_id                  = aws_vpc.sandbox_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.sandbox_vpc.id
}

# Route Table
resource "aws_route_table" "sandbox_rt" {
  vpc_id = aws_vpc.sandbox_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Route Table Association
resource "aws_route_table_association" "sandbox_rta" {
  subnet_id      = aws_subnet.sandbox_subnet.id
  route_table_id = aws_route_table.sandbox_rt.id
}

# Security Group
resource "aws_security_group" "sandbox_sg" {
  name        = "sandbox_sg"
  description = "Allow HTTP, SSH"
  vpc_id      = aws_vpc.sandbox_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Web Server
resource "aws_instance" "web_server" {
  ami                         = "ami-0150ccaf51ab55a51"  # Ubuntu 24.04 LTS
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.sandbox_subnet.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.shubham.key_name
  vpc_security_group_ids      = [aws_security_group.sandbox_sg.id]


  tags = {
    Name = "WebServer"
  }
}