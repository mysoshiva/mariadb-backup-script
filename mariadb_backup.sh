################################################################################################
#!/bin/bash
# NAME:
#       mariadb_backup.sh
# DESCRIPTION:
#       Takes a  backup from MariaDB and delete the dump older than $BKP_RETENTION=5 days.
# INPUTS:
#
# OUTPUTS:
#       Back-up Location     /var/backup/mdbbackup/ (Please change the variable if needed)
#       E-mail
# CHANGES:
#       DATE           WHO                DETAIL
#      2020-07-17      shivamysore            V.1
################################################################################################
# Add the backup dir location, MariaDB username and password
CHECK_PARM=$1
MAIL_RECPT="xxxxx@gmail.com"
DATE=$(date +%d-%m-%Y)
BKP_DIR="/home/smysore/mdbbackup"
MDB_USER="root"
MDB_PASSWORD="xxxx"
HOST_NAME=`uname -n`
BKP_LOG_DIR="$BKP_DIR/$DATE/mdb.log"
BKP_RETENTION=5

# To create a new directory in the backup directory location based on the DATE
mkdir -p $BKP_DIR/$DATE

echo "-- Script: $(basename "$0") STARTED at `date` on $HOST_NAME"  >> $BKP_LOG_DIR

# To capture the error and trigger email notification
function error_mail()
{
  echo "$1" | mailx -s "MariaDB BackUp Process was not successful on $HOST_NAME" $MAIL_RECPT
}

# Trigger email notification on successful backup process
function success_mail()
{
  echo "$1" | mailx -s "MariaDB BackUp Process was successful on $HOST_NAME" $MAIL_RECPT
}

# To capture mysqldump for each DB into seperate file.
function each_db()
{
  # To get a list of databases
  databases=`mysql -u $MDB_USER -p$MDB_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema)"`
  echo -e "Below are the list of Databases:\n$databases" >> $BKP_LOG_DIR

  # To dump each database in a separate file
  for db in $databases; do
  echo $db
  mysqldump -u $MDB_USER -p$MDB_PASSWORD --lock-tables=false --databases $db | gzip > $BKP_DIR/$DATE/$db.sql.gz
  if [ "$?" -ne 0 ]; then
    echo "mysqldump command failed for $db on $HOST_NAME" >> $BKP_LOG_DIR
    error_mail "mysqldump command failed for $db on $HOST_NAME"
  else
    echo "mysqldump completed for $db" >> $BKP_LOG_DIR
  fi
  done
  success_mail "mysqldump command completed on $HOST_NAME"
}

# To capture mysqldump for all DB's into single file.
function all_dbs()
{
  mysqldump -u $MDB_USER -p$MDB_PASSWORD --lock-tables=false --all-databases | gzip > $BKP_DIR/$DATE/full-backup-$HOST_NAME.sql.gz
  if [ "$?" -ne 0 ]; then
    echo "mysqldump command failed on $HOST_NAME" >> $BKP_LOG_DIR
    error_mail "mysqldump command failed for $db on $HOST_NAME"
  else
    echo "mysqldump completed for all DB's" >> $BKP_LOG_DIR
  fi
}

# Trigger the function based on the argument each_db ot all_dbs
case ${CHECK_PARM} in
   each_db)echo "This is will dump each DB into a seperate file" >> $BKP_LOG_DIR
      each_db
      ;;
   all_dbs)echo "This is will dump all DB's into a single file" $BKP_LOG_DIR
      all_dbs
      ;;
   *)
      echo "`basename ${0}`:usage: [each_db] | [all_dbs]"
      echo "Arugument is missing each_db or all_dbs" >> $BKP_LOG_DIR
      exit 1 # Command to come out of the program with status 1
      ;;
esac

# Delete the files older than 5 days
find $BKP_DIR/* -mtime +"$BKP_RETENTION" -exec rm -Rf {} \;
if [ "$?" -ne 0 ]; then
  echo "Unable to delete Older Backups" >> $BKP_LOG_DIR
  error_mail "Task Failed at Deletion of older backups"
else
  echo "Deleted the Older Backups" >> $BKP_LOG_DIR
fi
