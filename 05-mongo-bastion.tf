# Contents:
# 1. Mongo instance
# 2. Bastion instance

# 1. Mongo Instance in a private subnet 
resource "aws_instance" "mongo_instance" {
  ami           = data.aws_ami.most_recent_amazon_ami.id
  instance_type = "t2.nano"
  subnet_id     = module.vpc.private_subnets[0] # Creates instance in private VPC subnet
  vpc_security_group_ids = [aws_security_group.mongo_sg.id]
  key_name = "firstLabKey" # Allows SSH from Bastion

  tags = {
    Name = "Mongo Database"
  }
}

# 2. Bastion instance to connect to the Mongo Instance
resource "aws_instance" "bastion_instance" {
  ami           = data.aws_ami.most_recent_amazon_ami.id
  instance_type = "t2.nano"
  subnet_id     = module.vpc.public_subnets[0] # Creates instance in public VPC subnet
  vpc_security_group_ids = [aws_security_group.bastion_sg.id] # Uses bastion security group
  key_name = "firstLabKey" # Currently allows ssh from anywhere

  tags = {
    Name = "Bastion Instance"
  }
}