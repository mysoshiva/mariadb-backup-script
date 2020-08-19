# mariadb-backup-script
This takes backups in two options:
![alt text](https://github.com/adam-p/markdown-here/raw/master/src/common/images/icon48.png "Logo Title Text 1") 1) **Take the backup of each DB into a separate file when we pass argument as "each_db"** 2) *Take the backup of all the DB's into a separate file when we pass argument as "all_dbs"* This script also ensures to delete the backups older than 5 days(configurable) execute as "mariadb-backup-script each_db" or "mariadb-backup-script all_dbs"
