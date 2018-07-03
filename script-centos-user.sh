#!/bin/bash

# Disable SELinux
sudo setenforce 0

# Disable SELinux permanently
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# Install git, nano, wget
sudo yum -y install git nano wget

# These three lines download Docker: Community Edition
# I want the community edition because it's a later version of the regular Docker
sudo yum -y install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y install docker-ce

# Enable docker to automatically start on boot
sudo systemctl enable docker

# Add the user to the docker group and then reboot to apply the changes
sudo usermod -aG docker $USER
sudo reboot









################################################################################
# Steps:
# 1. Create a new directory
# mkdir a && cd a
#
# 2. Download source of Node.JS application
# git clone https://github.com/TundraFizz/Docker-Example .
#
# 3. Create Docker image
# docker build -t sample-app sample-app
#
# 4. Build NGINX configuration files
# bash mollusk.sh nconf -c sample-app -s 34.218.241.246
# bash mollusk.sh nconf -c phpmyadmin -s 34.218.241.246 -p 9000
#
# 5. Deploy
# docker stack deploy -c docker-compose.yml sample
################################################################################
