#!/bin/bash

# Writing node config to script
cat << 'EOF' > /home/ec2-user/start_app.sh
#!/bin/bash

# Install Git
yum -y install git

echo "Installing Node.js and npm..."
yum -y install nodejs
npm install @hapi/hapi
echo "Node.js and npm installation complete."

# Write MongoDB config to mongodb-org file
echo "[mongodb-org-7.0]" > /etc/yum.repos.d/mongodb-org-7.0.repo
echo "name=MongoDB Repository" >> /etc/yum.repos.d/mongodb-org-7.0.repo
echo "baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/" >> /etc/yum.repos.d/mongodb-org-7.0.repo
echo "gpgcheck=1" >> /etc/yum.repos.d/mongodb-org-7.0.repo
echo "enabled=1" >> /etc/yum.repos.d/mongodb-org-7.0.repo
echo "gpgkey=https://pgp.mongodb.com/server-7.0.asc" >> /etc/yum.repos.d/mongodb-org-7.0.repo

# Install MongoDB
echo "Installing MongoDB"
yum install -y mongodb-org

echo "STARTING APP"

# Enable and start mongod service
echo "Enabling MongoDB"
systemctl enable mongod
echo "Starting MongoDB"
systemctl start mongod

# Clone the Playtime app repository
echo "CLONING PLAYTIME"
git clone https://github.com/wit-hdip-comp-sci-2023/playtime.git
echo "Changing to Playtime directory"
cd playtime/

# Install npm dependencies
echo "Installing dependencies"
npm install

# Copy .env file
echo "Copying .env file stuff"
cp .env_example .env
echo "cookie_name=playlist" > .env
echo "cookie_password=secretpasswordnotrevealedtoanyone" >> .env
echo "db=mongodb://127.0.0.1:27017/playtime?directConnection=true" >> .env

# Start the server
echo "NPM Run start"
npm run start
EOF

echo "Adding permissions"
chmod +x /home/ec2-user/start_app.sh

echo "STARTING start_app.sh"
/home/ec2-user/start_app.sh
