#!/bin/bash

# Default values for command-line options
staging=""
email=false
domains=()

generate_ssl(){
  width=$(tput cols)
  bar="="

  for (( i=1; i<=width-1; i++ )); do
    bar="$bar""="
  done
  echo $bar
  echo "| Generating SSL for: $1"
  echo $bar

  domain_name=$1
  volume_name=tundra_ssl_challenge

  # Check if NGINX configuration file exists
  nginx_config_path=./nginx_conf.d/$domain_name.conf
  if [ ! -f "$nginx_config_path" ]; then
    echo "ERROR: Configuration file was not found at $nginx_config_path"
    exit
  fi

  docker run -it --rm --name certbot          \
    -v tundra_ssl:/etc/letsencrypt            \
    -v tundra_ssl_challenge:/ssl_challenge    \
    certbot/certbot certonly --register-unsafely-without-email --webroot --agree-tos \
    -w /ssl_challenge -d "$domain_name" "$staging"

  # Only remove the lines if the above was successful
  lines=$(cat "./nginx_conf.d/$domain_name.conf" | grep -n ssl_certificate | cut -f1 -d:)
  count=0

  for i in $lines; do
    count=$((count+1))
  done

  if [ $count = 0 ]; then
    echo "No SSL certificate paths in the configuration file"
  else
    echo "Uncommenting SSL certificate paths in the configuration file"

    for i in $lines; do
      echo "Line: ""$i" "$(sed "$i"'!d' nginx_conf.d/fizzic.al.conf)"

      sed -i "$i""s/#//" "./nginx_conf.d/$domain_name.conf"
    done
  fi
}

check_options(){
  if [ $# = 0 ]; then
    echo "Usage: cert_final.sh [OPTION]... [DOMAIN]..."
    echo "Options:"
    echo "-s         Staging mode, generate SSL certs for testing"
    echo "-e=EMAIL   Optional email to use when generating certs"
    echo ""
    exit
  fi
}

scan_options(){
  # Scan the command-line options and arguments the user provided
  for i in "$@"; do

    # If it's an option
    if [ "${i:0:1}" = "-" ]; then

      # Option: Staging
      if [ "$i" = "-s" ]; then
        staging="--staging"

      # Option: Email
      elif [[ $i = "-e="* ]]; then
        email=${i:3}

      # Invalid option
      else
        echo "Invalid option: ""$i"
        exit
      fi

    # If it's not an option, then it will be a domain
    else
      # Store domain in array
      domains+=("$i")
    fi
  done

  # Create an ssl directory if it doesn't exist
  mkdir ssl -p

  for i in "${domains[@]}"
  do
    generate_ssl "$i"
  done
}

restart_nginx(){
  # Restart the NGINX server
  docker restart $(docker container ls | grep nginx | grep -Eo '^[^ ]+')
}

finished(){
  echo "=================================================="
  echo "====================== DONE ======================"
  echo "=================================================="
}

check_options "$@"
scan_options "$@"
restart_nginx
finished

###############################################
# RENEWAL SCRIPT
#
# docker run -it --rm --name certbot          \
#   -v /home/centos/swag/ssl:/etc/letsencrypt \
#   certbot/certbot renew
###############################################
