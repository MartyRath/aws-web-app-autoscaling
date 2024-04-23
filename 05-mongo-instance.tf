# Creating a monogo database in a private subnet
resource "aws_instance" "mongo_instance" {
  ami                    = data.aws_ami.most_recent_amazon_ami.id
  instance_type          = "t2.nano"
  subnet_id              = module.vpc.private_subnets[0] # Creates instance in first available VPC subnet
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  iam_instance_profile   = "LabInstanceProfile" # To be used to push custom metrics to CloudWatch

  # Running scripts to install/enable/start Apache web servers, and push custom metrics to CloudWatch

  user_data = var.web_server_script

  tags = {
    Name = "Mongo Database"
  }
}