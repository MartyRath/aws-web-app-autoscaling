#!/bin/bash
# Description: This script writes the required set up for the playtime web application to start_app.sh.
#               It also configures a static web page id.html with the instance id.

# Update OS
yum update -y

# Install Git
yum -y install git

# Install/enable and start Apache web server
yum install httpd -y
systemctl enable httpd
systemctl start httpd

# Add webpage with instance metadata to id.html
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
echo "<b>Instance ID:</b> $INSTANCE_ID" > /var/www/html/id.html

# Installation for web application
yum -y install nodejs
npm install @hapi/hapi
echo "Node.js and npm installation complete."

# Write MongoDB config to mongodb-org file. Supressing permission errors, file is being configured correctly.
echo "[mongodb-org-7.0]" | sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo >/dev/null
echo "name=MongoDB Repository" | sudo tee -a /etc/yum.repos.d/mongodb-org-7.0.repo >/dev/null
echo "baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/" | sudo tee -a /etc/yum.repos.d/mongodb-org-7.0.repo >/dev/null
echo "gpgcheck=1" | sudo tee -a /etc/yum.repos.d/mongodb-org-7.0.repo >/dev/null
echo "enabled=1" | sudo tee -a /etc/yum.repos.d/mongodb-org-7.0.repo >/dev/null
echo "gpgkey=https://pgp.mongodb.com/server-7.0.asc" | sudo tee -a /etc/yum.repos.d/mongodb-org-7.0.repo >/dev/null

# Write web application and mongo database configuration to start_app.sh script
sudo cat << 'EOF' > /home/ec2-user/start_app.sh
#!/bin/bash

# Install MongoDB, use sudo as not running from root.
# NOTE: This is the last echoed message from this script when attempting to run on start up from user_data
echo "Installing MongoDB"
sudo yum install -y mongodb-org

# Enable mongod service.
echo "Attempting to enable Mongod service"
if sudo systemctl enable mongod; then
  echo "Mongod service successfully enabled"
else
  echo "Mongod service failed. Reinstalling MongoDB"
  # Clean install if previous attempt failed.
  sudo yum -y remove mongodb-org mongodb-org-server mongodb-org-shell mongodb-org-mongos mongodb-org-tools
  sudo yum clean all
  sudo yum install -y mongodb-org
  sudo yum install -y mongodb-org
  sudo systemctl enable mongod
fi

echo "Starting Mongod service"
sudo systemctl start mongod

# Clone the Playtime app repository
echo "Cloning playtime from github"
sudo git clone https://github.com/wit-hdip-comp-sci-2023/playtime.git

echo "Changing to Playtime directory"
# Error handling if playtime clone failed
if [ -d "playtime" ]; then
  cd playtime/
  echo "Changed to playtime directory."
else
  echo "playtime directory does not exist."
  exit 1
fi

# Install web application dependencies
echo "Installing playtime dependencies"
sudo npm install

# Configuring .env file
echo "Congfiguring .env file"
sudo cp .env_example .env
sudo chmod +rw .env
sudo tee .env << ENV_EOF
cookie_name=playlist
cookie_password=secretpasswordnotrevealedtoanyone
db=mongodb://127.0.0.1:27017/playtime?directConnection=true
ENV_EOF

# Start app
sudo npm run start
EOF

#################################################################################
# Attempting to start applcation automatically via user data. Not working.
# Mongo installed before SIGTERM recieved for rest of start_app.sh. Cause unknown
#################################################################################

# Check if start_app.sh exists, and if not, wait and check again
FILE="/home/ec2-user/start_app.sh"
waited=0
timeout=30
while [ ! -f "$FILE" ]; do
    echo "File $FILE not found. Waiting..."
    sleep 5
    waited=$((waited + 5))
    if [ "$waited" -ge "$timeout"]; then
        echo "No start_app.sh created. Timeout."
        exit 1
    fi
done

# Adding permissions to start_app.sh
echo "Start_app.sh created. Adding permissions"
chmod +x /home/ec2-user/start_app.sh

# Ensure correct ownership and permissions
chown ec2-user:ec2-user /home/ec2-user/start_app.sh

# Attemping to start app from user data
echo "Starting start_app.sh"
su - ec2-user -c "/home/ec2-user/start_app.sh"