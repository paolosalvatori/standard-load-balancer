#!/bin/bash

sudo apt-get update -y 
sudo apt-get upgrade -y
sudo apt-get install -y nginx
echo "TCP Server: $HOSTNAME" | sudo tee -a /var/www/html/index.html