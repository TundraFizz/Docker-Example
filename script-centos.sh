#!/bin/bash

# Install docker and wget
yum -y install docker wget

# Create the "docker" group
groupadd docker

# Get all users
USERS=$(cat /etc/passwd | grep "/home" | cut --delimiter=: --fields=1)

# Add all users to the "docker" group
for x in $USERS
do
  usermod -aG docker $x
done

# Enable docker to automatically start on boot
systemctl enable docker

# Start docker
systemctl start docker

# Restart the machine so that group permissions are applied
reboot

#################################################################################
# For some reason, downloading the image is EXTREMELY SLOW when I do it through #
# this automated script. So instead, do the last three commands manually        #
#################################################################################

# Download the test image
wget -P /home/centos/ https://s3-us-west-2.amazonaws.com/leif-docker-images/node-test.tar

# Load the image
docker load -i /home/centos/node-test.tar

# Run the image on port 4000
docker run -p 4000:9001 leif/node-web-app
