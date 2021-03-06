#!/bin/bash
########################################################################################################################
# CHECK NAGIOS MYSQL-BACKUP
########################################################################################################################
SCRIPT_NAME="CHECK_NAGIOS_MYSQL-BACKUP"
SCRIPT_DESCRIPTION="Nagios Check Script for mysql-backup.sh"
SCRIPT_VERSION="1.1"
SCRIPT_AUTHOR="Gabriel Soltz"
SCRIPT_CONTACT="thegaby@gmail.com"
SCRIPT_DATE="22-03-2016"
SCRIPT_GIT="https://github.com/gabrielsoltz/scripts-backups"
SCRIPT_WEB="www.3ops.com"
########################################################################################################################

# VARIABLES
MYSQL_DB=dbname
DST_PATH=/data/backups/$MYSQL_DB
NAME=MYSQL-$MYSQL_DB
NAGIOS_DST_EXIT_FILE=$DST_PATH
NAGIOS_EXIT_FILE=BKP-$NAME.exit
NAGIOS_TIME_FILE=BKP-$NAME-TIME.exit

# CHECKS
if [[ $(cat $NAGIOS_DST_EXIT_FILE/$NAGIOS_EXIT_FILE) != 0 ]]; then
        echo "CRITICAL - EL BACKUP FALLO: "$(cat $NAGIOS_DST_EXIT_FILE/$NAGIOS_EXIT_FILE)
        exit 2
else
        if test "`find $NAGIOS_DST_EXIT_FILE/$NAGIOS_EXIT_FILE -mtime +2`"; then
                echo "CRITICAL - NO SE ENCUENTRA BACKUP RECIENTE"
                exit 2
        else
                echo "OK - BACKUP CORRECTO: "$(cat $NAGIOS_DST_EXIT_FILE/$NAGIOS_TIME_FILE)
                exit 0
        fi
fi
