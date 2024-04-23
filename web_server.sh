#!/bin/bash

echo "web server script running"

yum update -y

# Installing cron
yum install -y cronie cronie-anacron

yum install -y awscli

# Install Apache web server
yum install httpd -y

# Enable and start Apache
systemctl enable httpd
systemctl start httpd

# Create IMDSv2 session token
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`

# Write metadata to index.html
echo "<html><body>" > /var/www/html/index.html
echo "<hr>zThis instance is running in availability zone: " >> /var/www/html/index.html
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone >> /var/www/html/index.html
echo "<hr>The instance ID is: " >> /var/www/html/index.html
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id >> /var/www/html/index.html
echo "<hr>The instance type is: " >> /var/www/html/index.html
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-type >> /var/www/html/index.html
echo "</body></html>" >> /var/www/html/index.html