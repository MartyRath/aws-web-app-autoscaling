# Description: Creation of a VPC with public and private subnets.
#              Creation of security groups.

# VPC creation module with public and private subnets in three availability zones with one NAT gateway
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "myVPC"
  cidr = "10.0.0.0/16"

  # Availability zones to be used
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Creating three public and three private subnets
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  public_subnet_names = ["public_subnet_1", "public_subnet_2", "public_subnet_3"]
  private_subnet_names = ["private_subnet_1", "private_subnet_2", "private_subnet_3"]

  # Enabling and NAT gateway in just one availability zone for private subnets
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

################################################################
# Security groups
# Web server security group for instances in public subnets.
# Allows http from any IP address
resource "aws_security_group" "web_server_sg" {
  name        = "web-server-sg"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id

  # Allows HTTP traffic (port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "web-server-sg"
    Environment = "dev"
  }
}

# Bastion security group to access instances in private subnets.
# Allows SSH from any IP
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for bastion hosts"
  vpc_id      = module.vpc.vpc_id

  # Allows SSH (port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "bastion-sg"
    Environment = "dev"
  }
}

# For instances in private subnets. 
# Allows SSH from Bastion. Allows SQL from web server. 
resource "aws_security_group" "database_sg" {
  name        = "database-sg"
  description = "Security group for database servers"
  vpc_id      = module.vpc.vpc_id

  # Allow SSH from Bastion
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Allow MYSQL from web server
  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    security_groups = [aws_security_group.web_server_sg.id]
  }

  # Allow MYSQL/Aurora from web server
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_server_sg.id]
  }

  tags = {
    Name        = "database-sg"
    Environment = "dev"
  }
}