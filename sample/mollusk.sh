#!/bin/bash

#####################################################################################################
# Mollusk: A shell script for simplifying and automating the following tasks for my Docker projects #
# - Backing up databases                                                                            #
# - Restoring databases from backups that were previously created                                   #
# - Generating SSL certificates by using Let's Encrypt                                              #
#####################################################################################################

# Default values for command-line options
staging=""
email=false
domains=()
function_to_call=0

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
    # echo "Usage: mollusk.sh [OPTION]... [DOMAIN]..."
    echo "Usage: mollusk.sh [FUNCTION]"
    echo "Functions:"
    echo "ssl       "
    echo "backup    "
    echo "restore   "
    echo ""
    echo "Pass a function name for more information on how to use it"
    echo "Example: mollusk.sh backup"
    echo ""

    # echo "Options:"
    # echo "-s         Staging mode, generate SSL certs for testing"
    # echo "-e=EMAIL   Optional email to use when generating certs"
    # echo ""

    exit
  fi
}

check_options(){
  if [ $# = 0 ]; then
    echo "Usage: mollusk.sh [FUNCTION]"
    echo "Functions:"
    echo "backup    Backup the database"
    echo "restore   Restore the database"
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
  # mkdir ssl -p
  # I DON'T THINK I NEED TO CREATE AN SSL DIRECTORY ANYMORE

  for i in "${domains[@]}"
  do
    generate_ssl "$i"
  done
}



scan_options(){
  for i in "$@"; do
    # If it's an option
    if [ "${i:0:1}" = "-" ]; then
      echo "OPTION: $i"

    # If it's not an option, then it will be a function
    else

      # If the user already specified a function
      if [ $function_to_call != 0 ];then
        echo "You can only choose one function: backup or restore"
        exit

      elif [ "$i" = "backup" ]; then
        function_to_call="db_backup"

      elif [ "$i" = "restore" ]; then
        function_to_call="db_restore"

      else
        echo "Unkown function, must be either backup or restore"
        exit
      fi
    fi
  done

  if [ $function_to_call = 0 ];then
    echo "You must choose one function: backup or restore"
    exit
  fi

  $function_to_call
}

restart_nginx(){
  # Restart the NGINX server
  docker restart $(docker container ls | grep nginx | grep -Eo '^[^ ]+')
}

db_backup(){
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

db_restore(){
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
