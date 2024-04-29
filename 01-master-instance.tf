# Assignment Steps 1 & 2
# Contents:
# 1. Get most recent Amazon AMI
# 2. Main/master Instance
# 3. Custom AMI


################### 1. Get most recent Amazon AMI ##################################################
# Get most recent Amazon ami
data "aws_ami" "most_recent_amazon_ami" {
  most_recent = true
  owners      = ["amazon"]

  # Filter AMI search to include keyterms, using globbing for updated criteria
  filter {
    name   = "name"
    values = ["al2023-ami-2023*x86_64"]
  }

}

#################### 2. Main/master Instance ######################################################
# EC2 instance to be used for custom ami, launch template
resource "aws_instance" "main_web_server" {
  ami                    = data.aws_ami.most_recent_amazon_ami.id
  instance_type          = "t2.nano"
  subnet_id              = module.vpc.public_subnets[0] # Creates instance in first available public VPC subnet
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  iam_instance_profile   = "LabInstanceProfile" # To be used to push custom metrics to CloudWatch
  key_name               = "firstLabKey"        # Key name for ssh

  # Running script to upload start_app.sh script with web application config, and create static web page id.html
  user_data = file("${path.module}/deploy_app.sh")

  tags = {
    Name = "Main Web Server"
  }

}

####################### 3. Custom AMI ############################################################
# Custom AMI based on main web server instance
resource "aws_ami_from_instance" "custom_ami" {
  name               = "custom_ami"
  source_instance_id = aws_instance.main_web_server.id

  tags = {
    Name = "Custom Web Server AMI"
  }
}