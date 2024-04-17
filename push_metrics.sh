#!/bin/bash
# Pushing metrics from mem.sh to CloudWatch

echo "Running custom metrics script"

# Install AWS CLI
yum install aws-cli -y

# Installing cron
yum install cronie cronie-anacron -y

# Copy mem.sh onto the instance
echo '#!/bin/bash
echo "Executing mem.sh script"
TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

USEDMEMORY=$(free -m | awk 'NR==2{printf "%.2f\t", $3*100/$2 }')
TCP_CONN=$(netstat -an | wc -l)
TCP_CONN_PORT_80=$(netstat -an | grep 80 | wc -l)
IO_WAIT=$(iostat | awk 'NR==4 {print $5}')

aws cloudwatch put-metric-data --metric-name memory-usage --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $USEDMEMORY
aws cloudwatch put-metric-data --metric-name Tcp_connections --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $TCP_CONN
aws cloudwatch put-metric-data --metric-name TCP_connection_on_port_80 --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $TCP_CONN_PORT_80
aws cloudwatch put-metric-data --metric-name IO_WAIT --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $IO_WAIT
' > /usr/local/bin/mem.sh

# Give mem.sh executable permissions
chmod +x /usr/local/bin/mem.sh

# Ensure region is set to us-east-1
aws configure set region us-east-1

# Run mem.sh script
/usr/local/bin/mem.sh

# Run mem.sh every minute using cron
echo "* * * * * root /usr/local/bin/mem.sh" >> /etc/crontab

# Reload cron to apply the changes
systemctl reload crond