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

# Create the "docker" group
groupadd docker

# Get all users
USERS=$(cat /etc/passwd | grep "/home" | cut --delimiter=: --fields=1)

# Add all users to the "docker" group
for x in $USERS
do
  usermod -aG docker $x
done

# Add Google's DNS to the Docker daemon; this allows Docker containers to connect to the internet
# NOT NEEDED?!
# echo '{"dns": ["8.8.8.8", "8.8.4.4"]}' > /etc/docker/daemon.json

# Enable docker to automatically start on boot
systemctl enable docker

# Start docker
systemctl start docker

# Restart the machine so that group permissions are applied
reboot
