#!/bin/bash
########################################################################################################################
# CHECK NAGIOS MYSQL-BACKUP
########################################################################################################################
SCRIPT_NAME="CHECK_NAGIOS_MYSQL-BACKUP"
SCRIPT_DESCRIPTION="Nagios Check Script for mysql-backup.sh"
SCRIPT_VERSION="1.0"
SCRIPT_AUTHOR="Gabriel Soltz"
SCRIPT_CONTACT="thegaby@gmail.com"
SCRIPT_DATE="24-04-2015"
SCRIPT_GIT="https://github.com/gabrielsoltz/scripts-backups"
SCRIPT_WEB="www.3ops.com"
########################################################################################################################

# VARIABLES
NAME=
NAGIOS_DST_EXIT_FILE=
NAGIOS_EXIT_FILE=$NAGIOS_DST_EXIT_FILE/BKP-$NAME.exit
NAGIOS_TIME_FILE=$NAGIOS_DST_EXIT_FILE/BKP-$NAME-TIME.exit

# CHECKS
if [ $(cat $NAGIOS_EXIT_FILE) -ne 0 ]; then
	echo "CRITICAL - EL BACKUP FALLO: "$(cat $NAGIOS_EXIT_FILE)
	exit 2
else
	if ! find $NAGIOS_EXIT_FILE -ctime -2 > /dev/null; then
		echo "CRITICAL - NO SE ENCUENTRA BACKUP RECIENTE"
		exit 2
	else
		echo "OK - BACKUP CORRECTO: "$(cat $NAGIOS_TIME_FILE)
		exit 0
	fi
fi
