#!/bin/bash

# Disable SELinux
setenforce 0

# Disable SELinux permanently
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# Install nano and wget
yum -y install nano wget

# These three lines download Docker: Community Edition
# I want the community edition because it's a later version of the regular Docker
yum -y install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce

# Enable docker to automatically start on boot
systemctl enable docker

# Add all users to the docker group
USERS=$(cat /etc/passwd | grep "/home" | cut --delimiter=: --fields=1)

# Add all users to the "docker" group
for i in $USERS
do
  usermod -aG docker $i
done

# reboot to apply the changes
reboot

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
