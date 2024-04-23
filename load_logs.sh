#!/bin/bash

# Prompt user to enter the DNS name of the load balancer
read -p "Enter the IP address of the instance: " IP_ADDRESS

echo "Here is the log for $IP_ADDRESS"

ssh -o StrictHostKeyChecking=no -i firstLabKey.pem ec2-user@$IP_ADDRESS "sudo tail -f /var/log/httpd/access_log"

