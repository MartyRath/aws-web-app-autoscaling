# Step 1
# Description: Creation and configuration of a “master” instance of a web application.
# Defining ec2

# Get most recent Amazon ami
data "aws_ami" "most_recent_amazon_ami" {
  most_recent      = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["al2023-ami-2023*x86_64"]
  }

}

# EC2 instance to be used as template for custom AMI
resource "aws_instance" "main_web_server" {
    ami = data.aws_ami.most_recent_amazon_ami.id
    instance_type = "t2.nano"
    subnet_id = module.vpc.public_subnets[0]
    vpc_security_group_ids = [aws_security_group.web_server_sg.id]

    # Update OS and install/enable/start Apache web server
    user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install httpd -y
    systemctl enable httpd
    systemctl start httpd
    EOF

    tags = {
        Name = "Main Web Server"
    }
}

# Custom AMI creation from main web server instance
resource "aws_ami_from_instance" "custom_ami" {
  name = "custom_ami"
  source_instance_id = aws_instance.main_web_server.id

  tags = {
        Name = "Custom Web Server AMI"
    }
}




