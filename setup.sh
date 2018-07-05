#!/bin/bash

# Download source of Node.JS application
git clone https://github.com/TundraFizz/Docker-Example .
cd Docker-Example

# Create Docker image
docker build -t sample-app sample-app

# Build NGINX configuration files
bash mollusk.sh nconf -c sample-app -s ip
bash mollusk.sh nconf -c phpmyadmin -s ip -p 9000

# Initialize a Docker swarm and deploy
docker swarm init
docker stack deploy -c docker-compose.yml sample
