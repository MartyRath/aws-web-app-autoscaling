#!/bin/bash

# Install Git
yum -y install git

echo "Installing Node.js and npm..."
yum -y install nodejs
npm install @hapi/hapi
echo "Node.js and npm installation complete."

# Write MongoDB config to mongodb-org file using tee to allow install from repository
tee /etc/yum.repos.d/mongodb-org-7.0.repo > /dev/null <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF

# Install MongoDB
yum install -y mongodb-org

# Write to file
cat << 'EOF' > /home/ec2-user/start_app.sh
#!/bin/bash
echo "STARTING APP"

# Enable and start mongod service
systemctl enable mongod
systemctl start mongod

# Clone the Playtime app repository
git clone https://github.com/wit-hdip-comp-sci-2023/playtime.git
cd playtime/


# Install npm dependencies
/usr/bin/npm install

# Copy .env file
cp .env_example .env
echo "cookie_name=playlist" > .env
echo "cookie_password=secretpasswordnotrevealedtoanyone" >> .env
echo "db=mongodb://127.0.0.1:27017/playtime?directConnection=true" >> .env

# Start the server
/usr/bin/npm run start
EOF

chmod +x /home/ec2-user/start_app.sh

./home/ec2-user/start_app.sh