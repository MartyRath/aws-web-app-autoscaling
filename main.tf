# Description: Creation of a VPC with public and private subnets.
#              Creation of security groups.

# VPC creation
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "myVPC"
  cidr = "10.0.0.0/16"

  # Availability zones to be used
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Creating 3 public, 3 private subnets
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  public_subnet_names = ["public_subnet_1", "public_subnet_2", "public_subnet_3"]
  private_subnet_names = ["private_subnet_1", "private_subnet_2", "private_subnet_3"]

  # Enabling and NAT gateway in just one availability zone for private subnets to route their Internet traffic through
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

################################################################
