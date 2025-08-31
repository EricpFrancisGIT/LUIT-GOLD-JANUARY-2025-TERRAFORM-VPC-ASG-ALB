#!/bin/bash

sudo yum update -y
sudo yum install httpd -y
sudo systemctl start httpd.service
sudo systemctl enable httpd.service
sudo echo "GREETINGS BOIL and GHOULS from $(hostname -f) at Spirits of Samhain!!!" > /var/www/html/index.html

