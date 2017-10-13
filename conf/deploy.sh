#!/usr/bin/env bash

echo "-----------------"
echo "Update Package Manager"
echo "-----------------"
sudo apt-get update
sudo apt-get update --fix-missing
sudo apt-get install -y build-essential libssl-dev g++

echo "-----------------"
echo "Install Curl"
echo "-----------------"
sudo apt-get install -y curl

echo "-----------------"
echo "Install Git"
echo "-----------------"
sudo apt-get install -y git

echo "-----------------"
echo "Install Node LTS"
echo "-----------------"
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.1/install.sh | bash
source ~/.nvm/nvm.sh
nvm install 6.11.4
nvm alias default 6.11.4

echo "-----------------"
echo "Clone App"
echo "-----------------"
sudo git clone https://fa4aec2a4fea9cb2a3bd8a940cb5ae382a1c533a@github.com/desoukya/amrdesouky.git /var/www/amrdesouky.com

echo "-----------------"
echo "Install PM2"
echo "-----------------"
npm install -g pm2

echo "-----------------"
echo "Install NGNIX"
echo "-----------------"
sudo apt-get install -y nginx

echo "-----------------"
echo "Setup NGNIX"
echo "-----------------"

echo '
upstream amrdesouky_com {
    server 127.0.0.1:3000;
    keepalive 64;
}
server {
    listen 3000;
    server_name amrdesouky.com;
    root /var/www/amrdesouky.com;
    location / {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-NginX-Proxy true;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_max_temp_file_size 0;
        proxy_pass http://amrdesouky_com/;
        proxy_redirect off;
        proxy_read_timeout 240s;
    }
}
' | sudo tee /etc/nginx/sites-available/amrdesouky.com

echo '
server {
    listen 80;
    server_name amrdesouky.com;

    location / {
            client_max_body_size 200M;
            proxy_pass http://localhost:3000;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header Host $host;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header 'Access-Control-Allow-Origin' '*';
    }
}
' | sudo tee /etc/nginx/sites-available/default

sudo service nginx stop
sudo service nginx start

sudo chown -R $USER:$USER /var/www

echo "-----------------"
echo "Setting Up firewall"
echo "-----------------"

sudo apt-get install -y ufw

sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 'Nginx Full'


echo "-----------------"
echo "Setting Up logfiles"
echo "-----------------"

sudo touch /var/log/info.log
sudo touch /var/log/error.log
sudo chown $USER:$USER /var/log/info.log
sudo chown $USER:$USER /var/log/error.logq

echo "-------------------------"
echo "Setting Logstash Pre-Reqs"
echo "-------------------------"
cd ~/
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java8-installer -y

wget https://artifacts.elastic.co/downloads/logstash/logstash-5.5.2.deb
sudo dpkg -i logstash-5.5.2.deb

echo "-------------------------"
echo "Setting Logstash Pre-Reqs"
echo "-------------------------"
echo '
input {
  file {
    path => "/var/log/info.log"
  }
  file {
    path => "/var/log/error.log"
  }
}

output {
    elasticsearch {
      hosts => ["elastic.amrdesouky.com:80"]
      index => "ad-site"
  }
}
' | sudo tee /etc/logstash/conf.d/logstash.conf

echo "-------------------------"
echo "Start Logstash Service   "
echo "-------------------------"
sudo service logstash start

echo "-------------------"
echo "Enter App Directory"
echo "-------------------"
cd /var/www/amrdesouky.com

echo "-------------------"
echo "Run Application"
echo "-------------------"
npm i
pm2 start server.js --name AD