#!/bin/bash
# Description: Step 7 - After generating web traffic using generate_web_traffic.sh, use this script on auto-scaled instances
# connected to the load balancer to show the traffic is distributed across multiple instances.

# Prompt user to enter IP address of instance
read -p "Enter the IP address of the an auto-scaled instance: " IP_ADDRESS

echo "Here is the log for $IP_ADDRESS"

# SSH onto instance and view the Apache access log
ssh -o StrictHostKeyChecking=no -i firstLabKey.pem ec2-user@$IP_ADDRESS "sudo tail -f /var/log/httpd/access_log"