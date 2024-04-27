#!/bin/bash

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
sudo touch /etc/yum.repos.d/mongodb-org-7.0.repo
sudo chmod +rw /etc/yum.repos.d/mongodb-org-7.0.repo
echo "[mongodb-org-7.0]" > /etc/yum.repos.d/mongodb-org-7.0.repo
echo "name=MongoDB Repository" >> /etc/yum.repos.d/mongodb-org-7.0.repo
echo "baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/" >> /etc/yum.repos.d/mongodb-org-7.0.repo
echo "gpgcheck=1" >> /etc/yum.repos.d/mongodb-org-7.0.repo
echo "enabled=1" >> /etc/yum.repos.d/mongodb-org-7.0.repo
echo "gpgkey=https://pgp.mongodb.com/server-7.0.asc" >> /etc/yum.repos.d/mongodb-org-7.0.repo

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

# Copy .env file
echo "Copying .env file stuff"
sudo cp .env_example .env
sudo chmod +rw .env
echo "cookie_name=playlist" > .env
echo "cookie_password=secretpasswordnotrevealedtoanyone" >> .env
echo "db=mongodb://127.0.0.1:27017/playtime?directConnection=true" >> .env

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

echo "Sstart_app.sh created. Adding permissions"
chmod +x /home/ec2-user/start_app.sh

# Ensure correct ownership and permissions
chown ec2-user:ec2-user /home/ec2-user/start_app.sh

echo "STARTING start_app.sh"
su - ec2-user -c "/home/ec2-user/start_app.sh"
