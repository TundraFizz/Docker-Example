#!/bin/bash

# Update CentOS
# sudo yum -y update

# Disable SELinux
setenforce 0

# Disable SELinux permanently
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# Install nano and wget
yum -y install git nano wget

# These three lines download Docker: Community Edition
# I want the community edition because it's a later version of the regular Docker
yum -y install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce

# Enable docker to automatically start on boot
systemctl enable docker
systemctl start docker

# Add Google's DNS to the Docker daemon; this allows Docker containers to connect to the internet
echo '{"dns": ["8.8.8.8", "8.8.4.4"]}' > /etc/docker/daemon.json

# Add all users to the docker group
USERS=$(cat /etc/passwd | grep "/home" | cut --delimiter=: --fields=1)
for i in $USERS
do
  usermod -aG docker $i
done

# Reboot to apply the changes
reboot

# After reboot you may run: bash setup.sh
