#!/bin/bash

echo "web server script ran"

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
curl -H "X-aws-ec2-metadata-token: \$TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id/ >> /var/www/html/id.html