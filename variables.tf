variable "instance_name" {
    description = "Name tag of EC2 Instance"
    type        = string
    default     = "NewInstance"
}

variable "ec2_instance_type" {
    description = "AWS EC2 instance type"
    type = string
    default = "t2.nano"
}

variable "web_server_script" {
    default = <<-EOF
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
      TOKEN=\$(curl -X PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
      INSTANCE_ID=\$(curl -H "X-aws-ec2-metadata-token: \$TOKEN" http://169.254.169.254/latest/meta-data/instance-id/)
      echo \$INSTANCE_ID >> /var/www/html/id.html
      EOF
}
