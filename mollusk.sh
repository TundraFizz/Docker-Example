#!/bin/bash

#####################################################################################################
# Mollusk: A shell script for simplifying and automating the following tasks for my Docker projects #
# - Backing up databases                                                                            #
# - Restoring databases from backups that were previously created                                   #
# - Generating SSL certificates by using Let's Encrypt                                              #
# - Renewing SSL certificates                                                                       #
# - Generating basic NGINX configuration files                                                      #
#####################################################################################################

# Default values for command-line options
arguments=("$@")

help_main(){
  echo "Usage: mollusk.sh [FUNCTION]"
  echo ""
  echo "[FUNCTION]"
  echo "ssl     Create new SSL certificates"
  echo "nconf   Generate a basic NGINX config file"
  echo "renew   Renew SSL certificates"
  echo "backup  Backup the database"
  echo "restore Restore the database from most recent backup"
  echo ""
  echo "Pass a function name for more information on how to use it"
  echo "Example: mollusk.sh backup"
  echo ""
  exit
}

help_ssl(){
  echo "Usage: mollusk.sh ssl [PARAMETERS] [OPTIONS] [FLAGS]"
  echo ""
  echo "[PARAMETERS]"
  echo "-d  Domain for the SSL certificate, you may optionally specify a port number (default is 80)"
  echo "-se Service name of what you're creating the SSL certificate for"
  echo "-st Stack name that contains the service"
  echo ""
  echo "[OPTIONS]"
  echo "-e Email to use when generating certs"
  echo ""
  echo "[FLAGS]"
  echo "-s Staging mode, generate an SSL cert for testing (default is production)"
  echo ""
  echo "Example: mollusk.sh ssl -d example.com -se example-com -st sample"
  echo "Example: mollusk.sh ssl -d example.com:9001 -se example-com -st sample"
  echo "Example: mollusk.sh ssl -d example.com -se example-com -st sample -s"
  echo "Example: mollusk.sh ssl -d example.com:9001 -se example-com -st sample -e myself@example.com -s"
  echo ""
  exit
}

help_nconf(){
  echo "Usage: mollusk.sh nconf [PARAMETERS] [OPTIONS]"
  echo ""
  echo "[PARAMETERS]"
  echo "-c Container name that contains the service to forward to"
  echo "-s Server name(s); ip is special and will use the instance's public ipv4"
  echo ""
  echo "[OPTIONS]"
  echo "-p Port number (default = 80)"
  echo ""
  echo "Example: mollusk.sh nconf -c sample-app -s ip"
  echo "Example: mollusk.sh nconf -c phpmyadmin -s ip -p 9000"
  echo "Example: mollusk.sh nconf -c samples -s sample-data.com"
  echo "Example: mollusk.sh nconf -c example -s example.com 34.218.241.246"
  echo ""
  exit
}

help_backup(){
  echo "Usage: mollusk.sh backup [TBD]"
  echo ""
  echo "[TBD]"
  echo "-tbd tbd"
  echo ""
  echo "Example: mollusk.sh backup ???"
  echo ""
  exit
}

help_restore(){
  echo "Usage: mollusk.sh restore [TBD]"
  echo ""
  echo "[TBD]"
  echo "-tbd tbd"
  echo ""
  echo "Example: mollusk.sh restore ???"
  echo ""
  exit
}

pop_argument(){
  arguments=("${arguments[@]:1}")
}

options_nconf(){
  if [ ${#arguments[@]} = 0 ]; then
    help_nconf
  fi

  current_param=""
  container_name=""
  server_names=()
  port="80"

  for i in "${arguments[@]}"; do # Go through all user arguments

    # If the argument starts with a dash, then set it as the current parameter
    if [ "${i:0:1}" = "-" ]; then
      current_param="${i}"
    elif [ "${current_param}" = "-c" ]; then
      container_name="${i}"
    elif [ "${current_param}" = "-s" ]; then

      # Special case, get the EC2 instance's public IPv4 address
      if [ "${i}" = "ip" ]; then
        i="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
      fi

      server_names+=("${i}")
    elif [ "${current_param}" = "-p" ]; then
      port="${i}"
    else
      echo "ERROR! Unrecognized parameter: ${current_param}"
    fi
  done

  # Use the container's name as the upstream's name
  upstream_name="${container_name}"
  server_name=""

  for i in "${server_names[@]}"; do
    server_name+=" $i"
  done

  # Now generate the NXINX config file
  echo "upstream ${upstream_name} {server ${container_name}:80;}"   > "nginx_conf.d/${container_name}".conf
  echo "server {"                                                  >> "nginx_conf.d/${container_name}".conf
  echo "  listen ${port};"                                         >> "nginx_conf.d/${container_name}".conf
  echo "  server_name${server_name};"                              >> "nginx_conf.d/${container_name}".conf
  echo "  location / {proxy_pass http://${upstream_name};}"        >> "nginx_conf.d/${container_name}".conf
  echo "}"                                                         >> "nginx_conf.d/${container_name}".conf

  restart_nginx
}

options_ssl(){
  if [ "${#arguments[@]}" = 0 ]; then
    help_ssl
  fi

  domain=""
  service_name=""
  stack_name=""
  email="--register-unsafely-without-email"
  staging="false"

  for i in "${arguments[@]}"; do # Go through all user arguments
    # Handle flags first
    if [ "${i}" = "-s" ]; then # Flag: Staging
      staging="true"

    # If the argument starts with a dash, then set it as the current parameter/option
    elif [ "${i:0:1}" = "-" ]; then
      current_param="${i}"

    # Handle parameters and options
    elif [ "${current_param}" = "-d" ]; then # Parameter: Domain
      domain="${i}"
    elif [ "${current_param}" = "-se" ]; then # Parameter: Service name
      service_name="${i}"
    elif [ "${current_param}" = "-st" ]; then # Parameter: Stack name
      stack_name="${i}"
    elif [ "${current_param}" = "-e" ]; then # Option: Email
      email="--email ${i}"

    # Error
    else
      echo "Error: Unrecognized parameter: ${current_param}"
      exit
    fi
  done

  # Check if mandatory parameters have been supplied
  failed=""

  if [ "${domain}" = "" ]; then
    echo "Error: Missing parameter: -d"
    failed="true"
  fi

  if [ "${service_name}" = "" ]; then
    echo "Error: Missing parameter: -se"
    failed="true"
  fi

  if [ "${stack_name}" = "" ]; then
    echo "Error: Missing parameter: -st"
    failed="true"
  fi

  if [ "${failed}" = "true" ]; then
    exit
  fi

  # Get port number if the user supplied it
  IFS=":"
  read -ra temp <<< "${domain}"
  domain_name=${temp[0]}
  port_number=${temp[1]}
  if [ "${port_number}" = "" ]; then
    port_number="80"
  fi

  # Create a new configuration file for NGINX
  generate_conf_part_1 "$domain_name" "$service_name" "$port_number"
  restart_nginx

  if [ "${staging}" = "true" ]; then

    # Staging mode

    docker run -it --rm --name certbot                        \
    -v "${stack_name}"_ssl:/etc/letsencrypt                   \
    -v "${stack_name}"_ssl_challenge:/ssl_challenge           \
    certbot/certbot certonly "${email}" --webroot --agree-tos \
    -w /ssl_challenge --staging -d "${domain_name}"

    echo "COMPLETE: certbot in staging mode"

  else

    # Production mode

    docker run -it --rm --name certbot                        \
    -v "${stack_name}"_ssl:/etc/letsencrypt                   \
    -v "${stack_name}"_ssl_challenge:/ssl_challenge           \
    certbot/certbot certonly "${email}" --webroot --agree-tos \
    -w /ssl_challenge -d "${domain_name}"

    echo "COMPLETE: certbot in production mode"

  fi

  generate_conf_part_2 "${domain_name}"
  restart_nginx
}

options_backup_or_restore(){
  pop_argument # Remove the function

  # if [ ${#arguments[@]} = 0 ]; then
  #   help_"$1"
  # fi

  for i in "${arguments[@]}"; do # Go through all user arguments

    if [ "${i:0:1}" = "-" ]; then # If it's an option
      echo "OPTION: $i"
    fi

  done

  execute_"$1"
  restart_nginx
}

generate_conf_part_1(){
  domain_name="${1}"
  service_name="${2}"
  port_number="${3}"

  echo "upstream ${domain_name} {
  server ${service_name}:${port_number};
}

server {
  listen 80;
  server_name ${domain_name} www.${domain_name};

  location / {
    return 302 https://${domain_name}\$request_uri;
  }

  location /.well-known/acme-challenge/ {
    alias /ssl_challenge/.well-known/acme-challenge/;
  }
}" > ./nginx_conf.d/"${1}".conf
}

generate_conf_part_2(){
  domain_name="${1}"

  echo "
server {
  listen 443 ssl;
  server_name ${domain_name};

  ssl_certificate     /ssl/live/${domain_name}/fullchain.pem;
  ssl_certificate_key /ssl/live/${domain_name}/privkey.pem;

  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_prefer_server_ciphers on;
  ssl_ciphers \"ssl_ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS\";
  ssl_ecdh_curve secp384r1;
  ssl_session_cache shared:SSL:10m;
  ssl_session_tickets off;
  ssl_stapling on;
  ssl_stapling_verify on;
  resolver 8.8.8.8 8.8.4.4 valid=300s;
  resolver_timeout 5s;
  add_header Strict-Transport-Security \"max-age=63072000; includeSubdomains\";
  add_header X-Frame-Options DENY;
  add_header X-Content-Type-Options nosniff;

  ssl_dhparam /dhparam.pem;

  location / {proxy_pass http://${domain_name};}
}

server {
  listen 443 ssl;
  server_name www.${domain_name};
  ssl_certificate     /ssl/live/${domain_name}/fullchain.pem;
  ssl_certificate_key /ssl/live/${domain_name}/privkey.pem;
  return 302 https://${domain_name}\$request_uri;
}" >> ./nginx_conf.d/"${domain_name}".conf
}

execute_backup(){
  echo "Backing up the database..."

  # Save the container that has the word "mysql" in its name as a variable
  mysql_container=$(docker container ls | grep mysql | grep -Eo '^[^ ]+')

  # Make sure that the container has python-pip and AWS' CLI installed
  docker exec "$mysql_container" bash -c "apt-get update"
  docker exec "$mysql_container" bash -c "apt-get install -y python-pip"
  docker exec "$mysql_container" bash -c "pip install awscli"

  current_time=$(date "+%Y-%m-%dT%H-%M-%S")
  bucket_name="leif-mysql-backups"
  db_username="root"
  db_password="ENTER_PASSWORD_HERE"
  db_database="testing"
  db_filename="mysql-backup-$current_time.sql.gz"

  # Create a backup on the container (the mysqldump command will overwrite any existing mysql-backup file)
  docker exec "$mysql_container" bash -c "mysqldump -u $db_username -p$db_password $db_database | gzip -9 > $db_filename"

  # Send the backup to my AWS S3 bucket
  docker exec "$mysql_container" bash -c "aws s3 cp $db_filename s3://$bucket_name"

  # Remove the backup file on the container
  docker exec "$mysql_container" bash -c "rm $db_filename"
}

execute_restore(){
  echo "Restoring the database..."

  # Save the container that has the word "mysql" in its name as a variable
  mysql_container=$(docker container ls | grep mysql | grep -Eo '^[^ ]+')

  # Make sure that the container has python-pip and AWS' CLI installed
  docker exec "$mysql_container" bash -c "apt-get update"
  docker exec "$mysql_container" bash -c "apt-get install -y python-pip"
  docker exec "$mysql_container" bash -c "pip install awscli"

  bucket_name="leif-mysql-backups"
  db_username="root"
  db_password="ENTER_PASSWORD_HERE"
  db_database="testing"
  db_filename=$(docker exec "$mysql_container" bash -c "aws s3 ls $bucket_name | sort | tail -n 1" | awk '{print $4}')

  # Download the backup from S3
  docker exec "$mysql_container" bash -c "aws s3 cp s3://leif-mysql-backups/$db_filename $db_filename"

  # Create the database
  docker exec "$mysql_container" bash -c "mysql -u $db_username -p$db_password -e 'create database $db_database'"

  # Restore from backup
  docker exec "$mysql_container" bash -c "gunzip < $db_filename | mysql -u $db_username -p$db_password $db_database"

  # Remove the backup file on the container
  docker exec "$mysql_container" bash -c "rm $db_filename"
}

restart_nginx(){
  # docker restart "$(docker container ls | grep nginx | grep -Eo '^[^ ]+')"

  # Reloading NGINX config
  docker exec -it "$(docker container ls | grep nginx | grep -Eo '^[^ ]+')" nginx -s reload

  # Wait a little bit
  sleep 2

  # while ! docker container ls | grep nginx; do
  #   echo "Nothing yet, waiting..."
  #   sleep 1
  # done
  # echo "NGINX is back up and running!"
}

renew_certificates(){
  docker run -it --rm --name certbot        \
  -v /home/centos/swag/ssl:/etc/letsencrypt \
  certbot/certbot renew
}

main(){

  function="${arguments[0]}"
  pop_argument # Remove the function

  if [ "$function" = "ssl" ]; then

    options_ssl

  elif [ "$function" = "nconf" ]; then

    options_nconf

  elif [ "$function" = "renew" ]; then

    renew_certificates

  elif [ "$function" = "backup" ]; then

    options_backup_or_restore "backup"

  elif [ "$function" = "restore" ]; then

    options_backup_or_restore "restore"

  else
    help_main
  fi
}

main

echo "=================================================="
echo "====================== DONE ======================"
echo "=================================================="
