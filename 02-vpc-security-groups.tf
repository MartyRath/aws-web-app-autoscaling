# Assignment Step 3
# Contents:
# 1. VPC Module (including subnets)
# 2. Security Groups

######################## 1. VPC Module (including subnets) ######################################
# Creates VPC, subnets, custom route tables, internet gateway, NAT gateway, Network ACL
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "myVPC"
  cidr = "10.0.0.0/16"

  # Availability zones
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # Creating three public and three private subnets in three availability zones
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  public_subnet_names  = ["public_subnet_1", "public_subnet_2", "public_subnet_3"]
  private_subnet_names = ["private_subnet_1", "private_subnet_2", "private_subnet_3"]

  # Auto-assigns public IPv4 address for instances launched in public subnets
  map_public_ip_on_launch = true

  # Enabling and NAT gateway in just one availability zone for private subnets
  enable_nat_gateway = true
  single_nat_gateway = true

  # Disable creation of default security group
  manage_default_security_group = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

###################### 2. Security Groups #############################################
# 1. Web Server SG
# 2. Bastion SG
# 3. Mongo SG

# 1. Web server security group for instances in public subnets.
# Allows SSH, HTTP, HTTPS and custom TCP traffic from any IP address
resource "aws_security_group" "web_server_sg" {
  name        = "web-server-sg"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id

  # Allows SSH traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allows HTTP traffic (port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allows HTTPS traffic (port 443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allows custom TCP for Node app (port 3000)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allows all outbound traffic from anywhere, all protocols
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "web-server-sg"
    Environment = "dev"
  }
}

# 2. Bastion security group to access instances in private subnets.
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

  # Allows outbound ssh traffic from anywhere
  egress {
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

############################MONGO#############################
# 3. Mongo security group 
# Allows SSH from bastion and mongo traffic from node app.
resource "aws_security_group" "mongo_sg" {
  name        = "mongo-sg"
  description = "Security group for mongo servers"
  vpc_id      = module.vpc.vpc_id

  # Allow SSH from Bastion
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Allow Mongo traffic from web server security group
  ingress {
    from_port = 27017
    to_port   = 27017
    protocol  = "tcp"
    # Only allow access from web server security group, node app
    security_groups = [aws_security_group.web_server_sg.id]
  }

  tags = {
    Name        = "mongo-sg"
    Environment = "dev"
  }
}