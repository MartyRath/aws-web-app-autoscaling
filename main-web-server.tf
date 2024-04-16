# Step 1 and Step 2
# Description: Creation and configuration of a “master” instance of a web application.
#              Creation of a custom AMI based on your master instance

# Get most recent Amazon ami
data "aws_ami" "most_recent_amazon_ami" {
  most_recent      = true
  owners = ["amazon"]

  # Filter AMI search to include keyterms, using globbing for updated criteria
  filter {
    name = "name"
    values = ["al2023-ami-2023*x86_64"]
  }

}

# EC2 instance to be used for custom ami, launch template
resource "aws_instance" "main_web_server" {
    ami = data.aws_ami.most_recent_amazon_ami.id
    instance_type = "t2.nano"
    subnet_id = module.vpc.public_subnets[0] # Creates instance in first available VPC subnet
    vpc_security_group_ids = [aws_security_group.web_server_sg.id]

    # Update OS and install/enable/start Apache web server
    user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install httpd -y
    systemctl enable httpd
    systemctl start httpd

    # Adding web page with instnace metadata
    echo "<b>Instance ID:</b> " > /var/www/html/id.html
    TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
    curl -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/instance-id/ >> /var/www/html/id.html

    EOF

    tags = {
        Name = "Main Web Server"
    }

    # Add create before destroy?
}

# Custom AMI creation from main web server instance
resource "aws_ami_from_instance" "custom_ami" {
  name = "custom_ami"
  source_instance_id = aws_instance.main_web_server.id

  tags = {
        Name = "Custom Web Server AMI"
    }
}

##########################LAUNCH TEMPLATE#############################
# Creation of web server instance launch template
resource "aws_launch_template" "web_server_template" {
  name_prefix   = "web_server_" # Creates a unique name but with this prefix
  image_id      = aws_ami_from_instance.custom_ami.id
  instance_type = "t2.nano"
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]

  # Same user data as ec2 instance
  user_data = aws_instance.main_web_server.user_data

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Web Server Instance"
    }
  }
}

##########################TARGET GROUP#######################################
# Creating an instance target group to be used with application load balancer
resource "aws_lb_target_group" "web_server_tg" {
  name     = "web-server-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = module.vpc.vpc_id #ID of custom VPC
}

##########################APPLICATION LOAD BALANCER#################################
# Application load balancer
resource "aws_lb" "test_lb" {
  name               = "test-lb"
  load_balancer_type = "application"
  internal           = false
  subnets            = module.vpc.public_subnets # Public subnet ids
  security_groups    = [aws_security_group.web_server_sg.id]
}

#########################LISTENER##################################
# Listener for HTTP traffic
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.test_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_server_tg.arn
  }
}

