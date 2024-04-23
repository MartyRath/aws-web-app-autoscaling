#!/bin/bash

# Write the script to a file
cat << 'EOF' > /home/ec2-user/custom_metrics.sh
#!/bin/bash

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

#######################CUSTOM METRICS################################
echo "Running custom metrics"
      
# Ensure region is set to us-east-1
aws configure set region us-east-1

USEDMEMORY=$(free -m | awk 'NR==2{printf "%.2f\t", $3*100/$2 }')
TCP_CONN=$(netstat -an | wc -l)
TCP_CONN_PORT_80=$(netstat -an | grep 80 | wc -l)
IO_WAIT=$(iostat | awk 'NR==4 {print $5}')

# Added error handling for AWS CLI commands
if ! aws cloudwatch put-metric-data --metric-name memory-usage --dimensions Instance=$INSTANCE_ID --namespace "2304Custom" --value $USEDMEMORY; then
    echo "Error pushing memory usage metric to CloudWatch"
fi
if ! aws cloudwatch put-metric-data --metric-name Tcp_connections --dimensions Instance=$INSTANCE_ID --namespace "2304Custom" --value $TCP_CONN; then
    echo "Error pushing TCP connections metric to CloudWatch"
fi
if ! aws cloudwatch put-metric-data --metric-name TCP_connection_on_port_80 --dimensions Instance=$INSTANCE_ID --namespace "2304Custom" --value $TCP_CONN_PORT_80; then
    echo "Error pushing TCP connections on port 80 metric to CloudWatch"
fi
if ! aws cloudwatch put-metric-data --metric-name IO_WAIT --dimensions Instance=$INSTANCE_ID --namespace "2304Custom" --value $IO_WAIT; then
    echo "Error pushing IO wait metric to CloudWatch"
fi
EOF

# Make the script executable
chmod +x /home/ec2-user/custom_metrics.sh

# Add a cron job to run the script every minute
echo "* * * * * /home/ec2-user/custom_metrics.sh >> /var/log/custom_metrics.log 2>&1" | crontab -