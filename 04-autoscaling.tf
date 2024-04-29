# Assignment Step 4 (Autoscaling) & Step 5
# Contents:
# 1. Launch Template
# 2. Autoscaling Group
# 3. Autoscaling Policies
# 4. CloudWatch Alarms

########################### 1. Launch Template #################################################
# Creation of launch template based on custom AMI. (see 01-master-instance.tf)
resource "aws_launch_template" "web_server_template" {
  image_id               = "ami-05f8f6156bbb015e2" # Uses custom AMI with local mongodb
  instance_type          = "t2.nano"
  vpc_security_group_ids = [aws_security_group.web_server_sg.id] # Define security group
  key_name               = "firstLabKey"                         # Key pair for SSH access

  # Enables detailed monitoring every minute instead of 5 mins
  monitoring {
    enabled = true
  }

  # To be used to push custom metrics to CloudWatch
  iam_instance_profile {
    name = "LabInstanceProfile"
  }

  # Starts node app for autoscaled instances
  user_data = base64encode(<<-EOF
  #!/bin/bash
  su - ec2-user -c 'cd playtime; npm run start'
  EOF
  )

  tags = {
    Name = "My Launch Template"
  }

}

########################### 2. Autoscaling Group #################################################
# Creates auto-scaling group based on launch template and linked to load balancer
resource "aws_autoscaling_group" "web_server_asg" {
  name                      = "web-server-asg"
  max_size                  = 3
  min_size                  = 1 
  desired_capacity          = 1
  vpc_zone_identifier       = module.vpc.public_subnets               # Public subnet ids
  target_group_arns         = [aws_lb_target_group.web_server_tg.arn] # Attach to load balancer target group
  health_check_grace_period = 30                                      # Default 300
  metrics_granularity       = "1Minute"                               # Enables group metrics within CloudWatch

  # Launch template to be used for instances
  launch_template {
    id      = aws_launch_template.web_server_template.id
    version = "$Latest"
  }

  # Adds timestamp to autoscaled instance names
  tag {
    key                 = "Name"
    value               = "Autoscaled Instance ${formatdate("HH:MM:ss", timestamp())}"
    propagate_at_launch = true
  }
}

########################### 3. Autoscaling Policies #########################################
# Policies include:
# 1. Scale out on high CPU
# 2. Scale in on low CPU

# 1. Create simple(default) scaling policy to scale out on high CPU
resource "aws_autoscaling_policy" "scale_out_high_CPU_asp" {
  name                   = "scale-out-high-CPU-asp"
  scaling_adjustment     = 1                  # Adds one instance
  adjustment_type        = "ChangeInCapacity" # Changes how many instances running
  cooldown               = 30                 # Default 300 secs
  autoscaling_group_name = aws_autoscaling_group.web_server_asg.name
}

# 2. Create a scaling policy to scale in on low CPU
resource "aws_autoscaling_policy" "scale_in_low_CPU_asp" {
  name                   = "scale-in-low-CPU-asp"
  scaling_adjustment     = -1 # Removes one instance
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 30
  autoscaling_group_name = aws_autoscaling_group.web_server_asg.name
}

########################### 4. CloudWatch Alarms ###########################################
# Alarms include:
# 1. High CPU
# 2. Low CPU

# 1. Alarm triggered when CPU usage exceeds 40% for 1 minute. No SNS set up
resource "aws_cloudwatch_metric_alarm" "high_CPU_alarm" {
  alarm_name          = "high-CPU-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2 # Two conseutive checks before triggering
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60 # 1 minute
  statistic           = "Average"
  threshold           = 40 # CPU usage percentage
  alarm_description   = "Alarm triggered when CPU usage exceeds 40% for 1 minute"

  # Attaches to scale out on high CPU autoscaling policy
  alarm_actions = [aws_autoscaling_policy.scale_out_high_CPU_asp.arn]
}

# 2. Alarm triggered when CPU usage is below 20% for 1 minute.
resource "aws_cloudwatch_metric_alarm" "low_CPU_alarm" {
  alarm_name          = "low-CPU-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2 # 2 consecutive checks before triggering alarm
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60 # 1 minute
  statistic           = "Average"
  threshold           = 20 # CPU usage percentage
  alarm_description   = "Alarm triggered when CPU usage is below 20% for 5 minutes"

  # Attaches to scale in on low CPU autoscaling policy
  alarm_actions = [aws_autoscaling_policy.scale_in_low_CPU_asp.arn]
}