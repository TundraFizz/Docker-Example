#!/bin/bash

docker run -it --rm --name certbot          \
  -v /home/centos/swag/ssl:/etc/letsencrypt \
  certbot/certbot renew
