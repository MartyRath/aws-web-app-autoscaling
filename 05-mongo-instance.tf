
# Creates a Mongo Instance in a private subnet 

resource "aws_instance" "mongo_instance" {
  ami           = data.aws_ami.most_recent_amazon_ami.id
  instance_type = "t2.nano"
  subnet_id     = module.vpc.private_subnets[0] # Creates instance in private VPC subnet
  # Currently alows ssh from anywhere
  vpc_security_group_ids = [aws_security_group.mongo_sg.id]
  iam_instance_profile   = "LabInstanceProfile" # To be used to push custom metrics to CloudWatch

  key_name = "firstLabKey"

  tags = {
    Name = "Mongo Database"
  }
}