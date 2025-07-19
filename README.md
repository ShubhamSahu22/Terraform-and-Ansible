# Terraform-and-Ansible
Terraform and Ansible
Overview
In today’s DevOps-driven world, automating infrastructure provisioning and configuration management has become the norm. In this blog post, I’ll walk you through how I automated the deployment of an EC2 instance on AWS using Terraform, and then configured the instance using Ansible — a practical integration of two powerful Infrastructure as Code (IaC) tools.

The goal is to:

Provision a sandbox environment on AWS using Terraform.
Automatically configure the EC2 instances using Ansible (in this case, install and run Nginx).
Use dynamic inventory with Ansible to connect to freshly created EC2s.
Why Terraform and Ansible?
Before we dive into the implementation, let’s briefly understand these tools:

Terraform

Terraform, developed by HashiCorp, is an open-source tool for provisioning and managing infrastructure using a declarative configuration language (HCL). With Terraform, you can define your entire cloud architecture (networks, subnets, instances, IAM, etc.) as code, version it, and reproduce it reliably.

Ansible

Ansible is an agentless configuration management tool that automates software provisioning, configuration management, and application deployment. It uses YAML-based playbooks and SSH to execute commands on remote machines.

What we built
We created an automated pipeline where:

Terraform provisions:

A VPC, subnet, and internet gateway.
A security group allowing HTTP and SSH access.
An EC2 instance with a public IP and an SSH key.
Ansible connects to this instance using the dynamic inventory (aws_ec2 plugin), installs Nginx, and configures it.

Task 1. Provisioning EC2 Infrastructure with Terraform
We start by writing Terraform configuration files:

terraform.tf

We mention the AWS provider and necessary version details.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
  required_version = ">= 1.2"
}
main.tf

This is the primary configuration file where we define all the actual AWS resources to be created. It acts as the blueprint for our cloud infrastructure. In the main.tf file we mention all the mention various setting to the sandbox like VPC, security group, route table, subnets, and key pair.

provider "aws" {
  region = var.region
}

# Upload public key to AWS as Key Pair
resource "aws_key_pair" "sandbox_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
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
  ami                         = "ami-007855ac798b5175e"  # Ubuntu 24.04 LTS
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.sandbox_subnet.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.sandbox_key.key_name
  vpc_security_group_ids      = [aws_security_group.sandbox_sg.id]


  tags = {
    Name = "WebServer"
  }
}
variables.tf

Declaring variables makes our Terraform code reusable and configurable. It allows us to pass different values without modifying the actual logic in main.tf.

variable "region" {
  default = "us-east-1"
}

variable "key_name" {
  description = "SSH key pair name"
}

variable "public_key_path" {
  description = "Path to your public SSH key"
}
Once the above files are created, we can execute terraform initto initialize a Terraform configuration in a working directory.


terraform init output
Run terraform validate to check whether your Terraform configuration files are syntactically valid. It parses all the .tf files and verifies correct syntax, variable definitions, and provider declarations.


terraform fmt and validate
Once the validation is successful, run terraform plan command which generates an execution plan showing what Terraform will do when you apply the configuration. Evaluates your .tf code and compares it with current infrastructure. Displays which resources will be created, updated, or destroyed. Consider it as a dry run where it does not make any actual changes.

Get Vrushal Kamate’s stories in your inbox
Join Medium for free to get updates from this writer.

Enter your email
Subscribe
Enter the ssh key details, the name and local folder location where the public key is stored.


As shown in the screenshot below, 8 resources will be added to the AWS.


After reviewing the plan and confirming that it is good to proceed you can run terraform apply which executes the actions defined in the Terraform plan to provision or update your infrastructure.