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

# Start docker
sudo systemctl start docker

# Add the user to the docker group and then reboot
sudo usermod -aG docker $USER
sudo reboot

################################################################################
# Steps:

# 1. Download source of Node.JS application
git clone https://github.com/TundraFizz/Docker-Example .

# 2. Create Docker image
cd sample-app
docker build -t sample-app .
cd ..

# 3. Download setup files [single_files | docker-compose | mollusk.sh]
# 4.
# 5.
# 6.
################################################################################

# Restart the machine so that group permissions are applied
sudo reboot
