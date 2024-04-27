#!/bin/bash

# Update OS
yum update -y
# Install Apache web server
yum install httpd -y
# Enable and start Apache
systemctl enable httpd
systemctl start httpd
# Add webpage with instance metadata
echo "<b>Instance ID:</b> " > /var/www/html/id.html
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" \
-H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
curl -H "X-aws-ec2-metadata-token: $TOKEN" \
http://169.254.169.254/latest/meta-data/instance-id/ >> /var/www/html/id.html

# Check if script is running as root
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Writing node config to script
cat << 'EOF' > /home/ec2-user/start_app.sh
#!/bin/bash

# Install Git
sudo yum -y install git

echo "Installing Node.js and npm..."
sudo yum -y install nodejs
sudo npm install @hapi/hapi
echo "Node.js and npm installation complete."

# Write MongoDB config to mongodb-org file
echo "[mongodb-org-7.0]" | sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo >/dev/null
echo "name=MongoDB Repository" | sudo tee -a /etc/yum.repos.d/mongodb-org-7.0.repo >/dev/null
echo "baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/" | sudo tee -a /etc/yum.repos.d/mongodb-org-7.0.repo >/dev/null
echo "gpgcheck=1" | sudo tee -a /etc/yum.repos.d/mongodb-org-7.0.repo >/dev/null
echo "enabled=1" | sudo tee -a /etc/yum.repos.d/mongodb-org-7.0.repo >/dev/null
echo "gpgkey=https://pgp.mongodb.com/server-7.0.asc" | sudo tee -a /etc/yum.repos.d/mongodb-org-7.0.repo >/dev/null


# Install MongoDB, use sudo as not running from root
echo "Installing MongoDB"
sudo yum install -y mongodb-org

echo "Starting Mongo"

# Enable and start mongod service
echo "Enabling MongoDB"
sudo systemctl enable mongod
echo "Starting MongoDB"
sudo systemctl start mongod

# Clone the Playtime app repository
echo "CLONING PLAYTIME"
sudo git clone https://github.com/wit-hdip-comp-sci-2023/playtime.git
echo "Changing to Playtime directory"

if [ -d "playtime" ]; then
  cd playtime/
  echo "Changed to 'playtime' directory."
else
  echo "'playtime' directory does not exist."
  exit 1
fi

# Install npm dependencies
echo "Installing dependencies"
sudo npm install


sudo cp .env_example .env
sudo chmod +rw .env
sudo tee .env << ENV_EOF
cookie_name=playlist
cookie_password=secretpasswordnotrevealedtoanyone
db=mongodb://127.0.0.1:27017/playtime?directConnection=true
ENV_EOF


# Start the server
echo "NPM Run start"
sudo npm run start
EOF

FILE="/home/ec2-user/start_app.sh"

waited=0
timeout=30
# Check if the file exists, and if not, wait and check again
while [ ! -f "$FILE" ]; do
    echo "File $FILE not found. Waiting..."
    sleep 5
    waited=$((waited + 5))
    if [ "$waited" -ge "$timeout"]; then
        echo "No start_app.sh created. Timeout."
        exit 1
    fi
done

echo "Start_app.sh created. Adding permissions"
chmod +x /home/ec2-user/start_app.sh

# Ensure correct ownership and permissions
chown ec2-user:ec2-user /home/ec2-user/start_app.sh

echo "STARTING start_app.sh"
su - ec2-user -c "/home/ec2-user/start_app.sh"
