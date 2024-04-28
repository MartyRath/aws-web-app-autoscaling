# Assignment Step 4 (Load Balancer)
# Contents:
# 1. Target Group
# 2. Application Load Balancer
# 3. Listeners

########################## 1. Target Group ######################################################
# Creating an instance target group to be used with application load balancer.
resource "aws_lb_target_group" "web_server_tg" {
  name        = "web-server-tg"
  port        = 3000 # Changed to forward traffic from 80 to 3000 node app
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = module.vpc.vpc_id #ID of custom VPC
}

########################## 2. Application Load Balancer ###################################
# Application load balancer
resource "aws_lb" "application_lb" {
  name               = "application-lb"
  load_balancer_type = "application"
  internal           = false
  subnets            = module.vpc.public_subnets # Public subnet ids
  security_groups    = [aws_security_group.web_server_sg.id]
}

########################## 3. Listeners ######################################################
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

# Listener for HTTPS traffic. Must be set up with Load Balancer DNS name, then insert cert ARN below.
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.application_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:701357344768:certificate/5775d573-eff3-411b-8679-5f6c2748e2c2"

  # Forward to target group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_server_tg.arn
  }
}