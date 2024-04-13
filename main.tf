terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0.0"
}

# Defining provider
provider "aws" {
  region = "us-east-1"
}

# VPC creation using module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "first-VPC"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  # Creating 3 public, 3 private subnets
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # Enabling and using just one NAT gateway for entire VPC
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
