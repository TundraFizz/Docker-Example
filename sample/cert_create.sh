#!/bin/bash

echo "Enter the domain name: "
read domain_name

directory_name=$(echo $domain_name | tr . _)

echo "Enter the directory name [$directory_name]:"
read tmp_dir

if [ ! -z $tmp_dir ]; then
  directory_name=$tmp_dir
fi

docker run -it --rm --name certbot                \
  -v /home/centos/swag/ssl:/etc/letsencrypt       \
  -v /home/centos/swag/$directory_name:/challenge \
  certbot/certbot certonly --register-unsafely-without-email --webroot --agree-tos -w /challenge -d $domain_name
