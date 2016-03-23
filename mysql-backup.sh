#!/bin/bash
########################################################################################################################
# MYSQL-BACKUP
########################################################################################################################
SCRIPT_NAME="MYSQL-BACKUP"
SCRIPT_DESCRIPTION="Backup Script for mysql, with gzip, encryption, rsync, loginpath, and nagios output."
SCRIPT_VERSION="2.0"
SCRIPT_AUTHOR="Gabriel Soltz"
SCRIPT_CONTACT="thegaby@gmail.com"
SCRIPT_DATE="22-03-2016"
SCRIPT_GIT="https://github.com/gabrielsoltz/scripts-backups"
SCRIPT_WEB="www.3ops.com"
########################################################################################################################
# HOW TO CREATE LOGINPATH:
# mysql_config_editor set --login-path=root --host=localhost --user=root --password
########################################################################################################################

# VARIABLES
MYSQL_DB=
MYSQL_LOGINPATH=
MYSQL_HOST=localhost
DST_PATH=
NAME=MYSQL-$MYSQL_DB
#MYSQL_DUMP_OPTIONS="--set-gtid-purged=OFF"

# CHECK DST PATH
if [ ! -d $DST_PATH ]; then
        echo "Creando Directorio: $DST_PATH"
        mkdir -p $DST_PATH
fi

# OUTPUT FOR: check_nagios_mysql_backup.sh (DST_NAGIOS_EXIT_FILE=0 LO DESHABILITA)
NAGIOS_DST_EXIT_FILE=$DST_PATH
NAGIOS_EXIT_FILE=BKP-$NAME.exit
NAGIOS_TIME_FILE=BKP-$NAME-TIME.exit
NAGIOS_STARTTIME=$(date +"%s")

# VARIABLES PARA GENERAR RSYNC. (DST_RMT_SERVER=0 LO DESHABILITA)
RMT_DST_SERVER=0
RMT_DST_PATH=
RMT_DST_USER=
RMT_DST_CERT=

## LOG
DATE=$(date +%m-%d-%Y_%H-%M)Hs
LOG=$DST_PATH/LOG-BKP-$NAME-$DATE.log
echo "--------------------------------------------------------" | tee -a $LOG
echo "SCRIPT: $SCRIPT_NAME" | tee -a $LOG
echo "VERSION: $SCRIPT_VERSION" | tee -a $LOG
echo "INICIO: $DATE" | tee -a $LOG
echo "--------------------------------------------------------" | tee -a $LOG

echo "----------------------------------------------------------" | tee -a $LOG
echo " Dump de Base de Datos..." | tee -a $LOG
echo "----------------------------------------------------------" | tee -a $LOG
MYSQL_FILE_BACKUP=BKP-$NAME-$DATE.sql
echo " Dumpeando en $DST_PATH/$MYSQL_FILE_BACKUP " | tee -a $LOG
sudo mysqldump --login-path=$MYSQL_LOGINPATH -h$MYSQL_HOST -l $MYSQL_DUMP_OPTIONS -r$DST_PATH/$MYSQL_FILE_BACKUP $MYSQL_DB 2>> $LOG 1>> $LOG \
&& { echo "OK" | tee -a $LOG ; EC_DUMP=0; } || { echo "! ERROR" | tee -a $LOG ; EC_DUMP=1; }

echo "----------------------------------------------------------" | tee -a $LOG
echo " Coprimiendo Dump..." | tee -a $LOG
echo "----------------------------------------------------------" | tee -a $LOG
echo " Comprimiendo archivo de backup: $DST_PATH/$MYSQL_FILE_BACKUP" | tee -a $LOG
sudo gzip -v $DST_PATH/$MYSQL_FILE_BACKUP 2>> $LOG 1>> $LOG \
&& { echo "OK" | tee -a $LOG ; EC_GZIP=0; } || { echo "! ERROR" | tee -a $LOG ; EC_GZIP=1; }

echo "----------------------------------------------------------" | tee -a $LOG
echo " Encripto Dump..." | tee -a $LOG
echo "----------------------------------------------------------" | tee -a $LOG
echo " Encriptando: $DST_PATH/$MYSQL_FILE_BACKUP.gz" | tee -a $LOG
openssl enc -aes256 -salt -k '$ENC_PASSWORD' -in $DST_PATH/$MYSQL_FILE_BACKUP.gz -out $DST_PATH/$MYSQL_FILE_BACKUP.gz.enc \
&& { echo "OK" | tee -a $LOG ; EC_ENC=0; rm -f $DST_PATH/$MYSQL_FILE_BACKUP.gz; } || { echo "! ERROR" | tee -a $LOG ; EC_ENC=1; }

echo "----------------------------------------------------------" | tee -a $LOG
echo " Nagios Exit Files..." | tee -a $LOG
echo "----------------------------------------------------------" | tee -a $LOG
if [ "$NAGIOS_DST_EXIT_FILE" != "0" ]; then
        if  [[ "$EC_DUMP" == "0" && "$EC_GZIP" == "0" && "$EC_ENC" == "0" ]]; then
                echo "0" | tee -a $LOG > $NAGIOS_DST_EXIT_FILE/$NAGIOS_EXIT_FILE
        else
                echo "EXIT CODE DUMP: $EC_DUMP" | tee -a $LOG > $NAGIOS_DST_EXIT_FILE/$NAGIOS_EXIT_FILE
                echo "EXIT CODE GZIP: $EC_GZIP" | tee -a $LOG >> $NAGIOS_DST_EXIT_FILE/$NAGIOS_EXIT_FILE
                echo "EXIT CODE ENC: $EC_ENC" | tee -a $LOG >> $NAGIOS_DST_EXIT_FILE/$NAGIOS_EXIT_FILE
        fi
        NAGIOS_ENDTIME=$(date +"%s")
        diff=$(($NAGIOS_ENDTIME-$NAGIOS_STARTTIME))
        echo " TIEMPO DEL PROCESO: $(($diff / 60)) MINUTOS Y $(($diff % 60)) SEGUNDOS." | tee -a $LOG > $NAGIOS_DST_EXIT_FILE/$NAGIOS_TIME_FILE
else
        echo "NAGIOS EXIT FILES: DISABLE." | tee -a $LOG
fi

echo "----------------------------------------------------------" | tee -a $LOG
echo " CHECK OLD..." | tee -a $LOG
echo "----------------------------------------------------------" | tee -a $LOG
OLDDAYS=180
find $DST_PATH \( -name "*.enc" -or -name "*.log" \) -type f -mtime +$OLDDAYS -exec rm {} \; -exec /bin/echo {} \; 2>> $LOG 1>> $LOG

echo "----------------------------------------------------------" | tee -a $LOG
echo " RSYNC..." | tee -a $LOG
echo "----------------------------------------------------------" | tee -a $LOG
if [ "$RMT_DST_SERVER" != "0" ]; then
	echo "" | tee -a $LOG
	echo " REMOTE SERVER: $RMT_DST_CERT" | tee -a $LOG
	rsync --delete-before -avze "ssh -i $RMT_DST_CERT" $DST_PATH/ $RMT_DST_USER@$RMT_DST_SERVER:$RMT_DST_PATH 2>> $LOG 1>> $LOG
else
	echo "RSYNC: DISABLE." | tee -a $LOG
fi
