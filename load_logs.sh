#!/bin/bash
# Description: Step 7 - View the Apache access log of instances to show that the 
#              load is distributed across more than one web server

# Prompt user to enter IP address of instance
read -p "Enter the IP address of the instance: " IP_ADDRESS

echo "Here is the log for $IP_ADDRESS"

ssh -o StrictHostKeyChecking=no -i firstLabKey.pem ec2-user@$IP_ADDRESS "sudo tail -f /var/log/httpd/access_log"

