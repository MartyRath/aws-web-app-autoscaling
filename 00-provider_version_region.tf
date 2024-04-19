# Defining required providers and versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0.0"
}

# Defining provider as AWS and region
provider "aws" {
  region = "us-east-1"
}