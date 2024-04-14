# Description: Creation of a VPC with public and private subnets.
#              Creation of security groups.

# VPC creation


################################################################
resource "aws_instance" "webServer" {
  ami = "ami-051f8a213df8bc089"
  instance_type = "t2.nano"

  tags = {
    Name = var.instance_name
  }

}