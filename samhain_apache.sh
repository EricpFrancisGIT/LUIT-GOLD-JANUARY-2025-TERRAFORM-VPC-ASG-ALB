#!/bin/bash

sudo yum update -y
sudo yum install httpd -y
sudo systemctl start httpd.service
sudo systemctl enable httpd.service
sudo echo "GREETINGS BOIL and GHOULS from $(hostname -f) at Spirits of Samhain!!!" > /var/www/html/index.html

DD_API_KEY=3b787f4153fb7e23287bc9e7ad460abd992d8391 DD_AGENT_MAJOR_VERSION=7 bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh)"