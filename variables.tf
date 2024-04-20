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
      echo "<hr>WEBSERVERSCRIPTThis instance is running in availability zone: " >> /var/www/html/index.html
      curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone >> /var/www/html/index.html
      echo "<hr>The instance ID is: " >> /var/www/html/index.html
      curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id >> /var/www/html/index.html
      echo "<hr>The instance type is: " >> /var/www/html/index.html
      curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-type >> /var/www/html/index.html
      echo "</body></html>" >> /var/www/html/index.html
      EOF     
}

variable "template_script" {
  default = <<-EOF
    #!/bin/bash

    # Create IMDSv2 session token
    TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`

    # Write metadata to index.html
    echo "<html><body>" > /var/www/html/index.html
    echo "<hr>shashahsaTEMPLATESCRIPTThis instance is running in availability zone: " >> /var/www/html/index.html
    curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone >> /var/www/html/index.html
    echo "<hr>The instance ID is: " >> /var/www/html/index.html
    curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id >> /var/www/html/index.html
    echo "<hr>The instance type is: " >> /var/www/html/index.html
    curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-type >> /var/www/html/index.html
    echo "</body></html>" >> /var/www/html/index.html  

    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

    USEDMEMORY=$(free -m | awk 'NR==2{printf "%.2f\t", $3*100/$2 }')
    TCP_CONN=$(netstat -an | wc -l)
    TCP_CONN_PORT_80=$(netstat -an | grep 80 | wc -l)
    IO_WAIT=$(iostat | awk 'NR==4 {print $5}')

    aws cloudwatch put-metric-data --metric-name memory-usage --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $USEDMEMORY
    aws cloudwatch put-metric-data --metric-name Tcp_connections --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $TCP_CONN
    aws cloudwatch put-metric-data --metric-name TCP_connection_on_port_80 --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $TCP_CONN_PORT_80
    aws cloudwatch put-metric-data --metric-name IO_WAIT --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $IO_WAIT

    # Ensure region is set to us-east-1
    aws configure set region us-east-1

    EOF
}