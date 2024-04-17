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