#!/bin/bash

function_to_call=0

check_options(){
  if [ $# = 0 ]; then
    echo "Usage: db_manage.sh [FUNCTION]"
    echo "Functions:"
    echo "backup    Backup the database"
    echo "restore   Restore the database"
    echo ""
    exit
  fi
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
  db_password="yolo"
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
  db_password="yolo"
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
finished
