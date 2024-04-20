variable "instance_name" {
  description = "Name tag of EC2 Instance"
  type        = string
  default     = "NewInstance"
}

variable "ec2_instance_type" {
  description = "AWS EC2 instance type"
  type        = string
  default     = "t2.nano"
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

       # Create IMDSv2 session token
      TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`

      # Write metadata to index.html
      echo "<html><body>" > /var/www/html/index.html
      echo "<hr>This instance is running in availability zone: " >> /var/www/html/index.html
      curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone >> /var/www/html/index.html
      echo "<hr>The instance ID is: " >> /var/www/html/index.html
      curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id >> /var/www/html/index.html
      echo "<hr>The instance type is: " >> /var/www/html/index.html
      curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-type >> /var/www/html/index.html
      echo "</body></html>" >> /var/www/html/index.html
      EOF     
}