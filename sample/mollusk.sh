#!/bin/bash

#####################################################################################################
# Mollusk: A shell script for simplifying and automating the following tasks for my Docker projects #
# - Backing up databases                                                                            #
# - Restoring databases from backups that were previously created                                   #
# - Generating SSL certificates by using Let's Encrypt                                              #
#####################################################################################################

# Default values for command-line options
staging=""
email="--register-unsafely-without-email"
domains=()
arguments=("$@")

help_main(){
  echo "Usage: mollusk.sh [FUNCTION]"
  echo ""
  echo "[FUNCTION]"
  echo "ssl       Create new SSL certificates"
  echo "renew     Renew SSL certificates"
  echo "backup    Backup the database"
  echo "restore   Restore the database from most recent backup"
  echo ""
  echo "Pass a function name for more information on how to use it"
  echo "Example: mollusk.sh backup"
  echo ""
  exit
}

help_ssl(){
  echo "Usage: mollusk.sh ssl [OPTIONS] [DOMAINS]"
  echo ""
  echo "[OPTIONS]"
  echo "-s         Staging mode, generate SSL certs for testing"
  echo "-e=EMAIL   Optional email to use when generating certs"
  echo ""
  echo "[DOMAINS]"
  echo "You can list as many domains as you want, delimited by spaces"
  echo ""
  echo "Example: mollusk.sh ssl -s -e=myself@example.com example.com testing.org"
  echo "Example: mollusk.sh ssl example.com testing.org"
  echo ""
  exit
}

help_backup(){
  echo "Usage: mollusk.sh backup [TBD]"
  echo ""
  echo "[TBD]"
  echo "-tbd   tbd"
  echo ""
  echo "Example: mollusk.sh backup ???"
  echo ""
  exit
}

help_restore(){
  echo "Usage: mollusk.sh restore [TBD]"
  echo ""
  echo "[TBD]"
  echo "-tbd   tbd"
  echo ""
  echo "Example: mollusk.sh restore ???"
  echo ""
  exit
}

pop_argument(){
  arguments=("${arguments[@]:1}")
}

options_ssl(){
  pop_argument # Remove the function

  if [ ${#arguments[@]} = 0 ]; then
    help_ssl
  fi

  for i in "${arguments[@]}"; do # Go through all user arguments

    if [ "${i:0:1}" = "-" ]; then # If it's an option

      if [ "$i" = "-s" ]; then # Option: Staging
        staging="--staging"

      elif [[ $i = "-e="* ]]; then # Option: Email
        email="--email ${i:3}"

      else
        help_ssl
      fi

    else # If it's not an option, it will be a domain
      domains+=("$i") # Store domain in array
    fi
  done

  for i in "${domains[@]}"; do
    generate_ssl "$i"
  done
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
  # volume_name=tundra_ssl_challenge

  # Check if NGINX configuration file exists
  nginx_config_path=./nginx_conf.d/$domain_name.conf
  if [ ! -f "$nginx_config_path" ]; then
    echo "ERROR: Configuration file was not found at $nginx_config_path"
    exit
  fi

  docker run -it --rm --name certbot          \
    -v tundra_ssl:/etc/letsencrypt            \
    -v tundra_ssl_challenge:/ssl_challenge    \
    certbot/certbot certonly "$email" --webroot --agree-tos \
    -w /ssl_challenge -d "$domain_name" "$staging"

  # Only remove the lines if the above was successful
  lines=$(< "./nginx_conf.d/$domain_name.conf" grep -n ssl_certificate | cut -f1 -d:)
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

execute_backup(){
  echo "Backing up the database..."

  # Save the container that has the word "mysql" in its name as a variable
  mysql_container=$(docker container ls | grep mysql | grep -Eo '^[^ ]+')

  # Make sure that the container has python-pip and AWS' CLI installed
  docker exec "$mysql_container" bash -c "apt-get update"
  docker exec "$mysql_container" bash -c "apt-get install -y python-pip"
  docker exec "$mysql_container" bash -c "pip install awscli"

  current_time=$(date "+%Y-%m-%dT%H:%M:%S")
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
  docker restart "$(docker container ls | grep nginx | grep -Eo '^[^ ]+')"
  # docker restart $(docker container ls | grep nginx | grep -Eo '^[^ ]+')
}

renew_certificates(){
  docker run -it --rm --name certbot        \
  -v /home/centos/swag/ssl:/etc/letsencrypt \
  certbot/certbot renew
}

main(){

  function="${arguments[0]}"

  if [ "$function" = "ssl" ]; then

    options_ssl

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
