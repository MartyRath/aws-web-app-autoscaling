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
    iam_instance_profile = "LabInstanceProfile" # To be used to push custom metrics to CloudWatch

    # Running scripts to install/enable/start Apache web servers, and push custom metrics to CloudWatch
 
    user_data = <<-EOF
      #!/bin/bash
      # Update OS
      yum update -y

      # Install Apache web server
      yum install httpd -y

      # Enable and start Apache
      systemctl enable httpd
      systemctl start httpd

      # Add webpage with instance metadata
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
# Creation of web server instance launch template. No key pair added
resource "aws_launch_template" "web_server_template" {
  name_prefix   = "web_server_" # Creates a unique name but with this prefix
  image_id      = aws_ami_from_instance.custom_ami.id # Uses custom AMI
  instance_type = "t2.nano"
  vpc_security_group_ids = [aws_security_group.web_server_sg.id] # Define security group

  # Same user data as main web server ec2 instance
  user_data = aws_instance.main_web_server.user_data

  # Enables detailed monitoring every minute instead of 5 mins
  monitoring {
    enabled = true
  }

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
resource "aws_lb" "application_lb" {
  name               = "application-lb"
  load_balancer_type = "application"
  internal           = false
  subnets            = module.vpc.public_subnets # Public subnet ids
  security_groups    = [aws_security_group.web_server_sg.id]
}

#########################LISTENER##################################
# Listener for HTTP traffic
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.application_lb.arn
  port              = "80"
  protocol          = "HTTP"

  # Forward to target group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_server_tg.arn
  }
}

##############################AUTO-SCALING GROUP#################################
# Creates
resource "aws_autoscaling_group" "web_server_asg" {
  name                      = "web-server-asg"
  max_size                  = 3
  min_size                  = 1
  desired_capacity          = 2 # Set to two as one is made to create ami
  vpc_zone_identifier       = module.vpc.public_subnets # Public subnet ids
  target_group_arns = [aws_lb_target_group.web_server_tg.arn] # Attach to load balancer target group
  health_check_grace_period = 30 # Default 300
  metrics_granularity = "1Minute" # Enables group metrics within CloudWatch

  launch_template {
    id      = aws_launch_template.web_server_template.id
    version = "$Latest"
  }

  tag {
    key = "Name"
    value = "Auto-scaled Instance"
    propagate_at_launch = true
  }

  }

