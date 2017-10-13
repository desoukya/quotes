# Initial setup

Make sure to create a new user `ubuntu` and add it to sudoers

1. `adduser ubuntu`
2. `usermod -aG sudo ubuntu`
3. sudo apt-get install vim -y
4. Disable password prompt: `sudo vim /etc/sudoers`
    append `ubuntu ALL=(ALL) NOPASSWD: ALL` to the end of the file
5. sudo su - ubuntu

# ELASTICSEARCH

Append The Following To `~/.bashrc`    

```
export LC_ALL="en_US.UTF-8"
```

Then Source 
```
source ~/.bashrc
```

```
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y build-essential software-properties-common

PRE-REQ (Install Oracle JDK 8)
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java8-installer -y

wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.5.2.deb
sudo dpkg -i elasticsearch-5.5.2.deb
```

This results in Elasticsearch being installed in `/usr/share/elasticsearch/` with its configuration files placed in `/etc/elasticsearch` and its init script added in `/etc/init.d/elasticsearch`

```
cd /usr/share/elasticsearch/
```

——
`sudo vim /etc/elasticsearch/elasticsearch.yml`

```
cluster.name: AD
node.name: AD_Node_01

network.host: [_local_]

indices.fielddata.cache.size:  50%
gateway.recover_after_time: 5m

network.publish_host: "69.164.217.198"
```

Configure how much memory elastic should use to startup (default 2GB)
`sudo vim /etc/elasticsearch/jvm.options`
```
-Xms2g
-Xmx2g
```
change to (512 MB)
```
-Xms512m
-Xmx512m
```
start elastic search
```
sudo service elasticsearch start
sudo service elasticsearch status
```

Allow connections to port 9200
```
sudo ufw allow 9200
```

Test connection
```
curl -i -XGET 'localhost:9200/'
```

LOGS:
`
sudo cat /var/log/elasticsearch/AD.log
`

# Setup Nginx

```
sudo apt install -y nginx
```

`sudo vim /etc/nginx/sites-available/default`
```
server {
        listen 80;
        server_name elastic.amrdesouky.com;

        location / {
                client_max_body_size 200M;
                proxy_pass http://localhost:9200;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header Host $host;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header 'Access-Control-Allow-Origin' '*';
        }
}
```

```
sudo service nginx stop
sudo service nginx start
```

Expose the ports:

```
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

Test connection again with domain
```
curl -i -XGET 'elastic.amrdesouky.com/'
```


to see the actual logs:
```
http://elastic.amrdesouky.com/ad-site/_search/?size=1000&pretty=1
…
      {
        "_index" : "ad-site",
        "_type" : "logs",
        "_id" : "AV41-qd4Z06yqcZoY-3c",
        "_score" : 1.0,
        "_source" : {
          "path" : "/var/log/messages",
          "@timestamp" : "2017-08-31T01:49:32.561Z",
          "@version" : "1",
          "host" : "ip-172-31-8-129",
          "message" : "testing logs from log stashserver"
        }
      },
…
```

# KIBANA

```
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y build-essential

Download and install the public signing key:
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

You may need to install the apt-transport-https package on Debian before proceeding:
sudo apt-get install apt-transport-https

Save the repository definition to /etc/apt/sources.list.d/elastic-5.x.list:
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list

You can install the Kibana Debian package with:
sudo apt-get update && sudo apt-get install kibana=5.5.2
```

```
sudo vim /etc/kibana/kibana.yml
```
```
elasticsearch_url: "http://elastic.amrdesouky.com"
server.port: 5601
server.host: "localhost"
server.name: "ad-kibana"
```
Start Kibana automatically

```
sudo service kibana start
```

modify nginx config

```
sudo vim /etc/nginx/sites-available/default
```

Add the following to the config
```
server {
        listen 80;
        server_name kibana.amrdesouky.com;
        access_log /var/log/nginx/localhost.log;

        location / {
                client_max_body_size 200M;
                proxy_pass http://localhost:5601;
                proxy_read_timeout 90;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header Host $host;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header 'Access-Control-Allow-Origin' '*';
        }
}
```

stop/start nginx so configuration changes take effect
```
sudo service nginx stop
sudo service nginx start
```

// make sure nothing is running on 5601
```
sudo lsof -i :5601
ps -ef | grep node
```

if so, kill it

`kill -9 {pid}`

// start kibana

`sudo service kibana start`

// by default, kibana writes to stdout, check logs and make sure everything is okay

`sudo cat /var/log/syslog`

```
Aug 31 01:06:30 ip-172-31-5-91 kibana[28632]: {"type":"log","@timestamp":"2017-08-31T01:06:30Z","tags":["status","plugin:kibana@5.5.2","info"],"pid":28632,"state":"green","message":"Status changed from uninitialized to green - Ready","prevState":"uninitialized","prevMsg":"uninitialized"}
Aug 31 01:06:30 ip-172-31-5-91 kibana[28632]: {"type":"log","@timestamp":"2017-08-31T01:06:30Z","tags":["status","plugin:elasticsearch@5.5.2","info"],"pid":28632,"state":"yellow","message":"Status changed from uninitialized to yellow - Waiting for Elasticsearch","prevState":"uninitialized","prevMsg":"uninitialized"}
Aug 31 01:06:30 ip-172-31-5-91 kibana[28632]: {"type":"log","@timestamp":"2017-08-31T01:06:30Z","tags":["status","plugin:console@5.5.2","info"],"pid":28632,"state":"green","message":"Status changed from uninitialized to green - Ready","prevState":"uninitialized","prevMsg":"uninitialized"}
Aug 31 01:06:30 ip-172-31-5-91 kibana[28632]: {"type":"log","@timestamp":"2017-08-31T01:06:30Z","tags":["status","plugin:metrics@5.5.2","info"],"pid":28632,"state":"green","message":"Status changed from uninitialized to green - Ready","prevState":"uninitialized","prevMsg":"uninitialized"}
Aug 31 01:06:30 ip-172-31-5-91 kibana[28632]: {"type":"log","@timestamp":"2017-08-31T01:06:30Z","tags":["status","plugin:elasticsearch@5.5.2","info"],"pid":28632,"state":"green","message":"Status changed from yellow to green - Kibana index ready","prevState":"yellow","prevMsg":"Waiting for Elasticsearch"}
Aug 31 01:06:30 ip-172-31-5-91 kibana[28632]: {"type":"log","@timestamp":"2017-08-31T01:06:30Z","tags":["status","plugin:timelion@5.5.2","info"],"pid":28632,"state":"green","message":"Status changed from uninitialized to green - Ready","prevState":"uninitialized","prevMsg":"uninitialized"}
Aug 31 01:06:30 ip-172-31-5-91 kibana[28632]: {"type":"log","@timestamp":"2017-08-31T01:06:30Z","tags":["listening","info"],"pid":28632,"message":"Server running at http://localhost:5601"}
Aug 31 01:06:30 ip-172-31-5-91 kibana[28632]: {"type":"log","@timestamp":"2017-08-31T01:06:30Z","tags":["status","ui settings","info"],"pid":28632,"state":"green","message":"Status changed from uninitialized to green - Ready","prevState":"uninitialized","prevMsg":"uninitialized"}
Aug 31 01:06:44 ip-172-31-5-91 systemd[1]: Started Kibana.
```

**Index name or pattern**

ad-site

**Time Filter field name**

@timestamp

http://kibana.amrdesouky.com
