#!/bin/bash
########################################################################################################################
# TARGZ-BACKUP
########################################################################################################################
SCRIPT_NAME="TARGZ-BACKUP"
SCRIPT_DESCRIPTION="Backup Script for files, with tar and gz, rsync, full or incremental mode and nagios output."
SCRIPT_VERSION="2.0"
SCRIPT_AUTHOR="Gabriel Soltz"
SCRIPT_CONTACT="thegaby@gmail.com"
SCRIPT_DATE="20-04-2015"
SCRIPT_GIT="https://github.com/gabrielsoltz/scripts-backups"
SCRIPT_WEB="www.3ops.com"
########################################################################################################################

# VARIABLES
NAME=www
BACKUP=/data/www
DST_PATH=/data/backups/www
SNAR_BACKUP=BKP-$NAME.snar

# OUTPUT FOR: check_nagios_targz_backup.sh (DST_NAGIOS_EXIT_FILE=0 LO DESHABILITA)
DST_NAGIOS_EXIT_FILE=0
NAGIOS_EXIT_FILE=BKP-$NAME.exit
NAGIOS_TIME_FILE=BKP-$NAME-TIME.exit
STARTTIME=$(date +"%s")

# VARIABLES PARA GENERAR RSYNC. (DST_RMT_SERVER=0 LO DESHABILITA)
DST_RMT_SERVER=0
DST_RMT_PATH=
DST_RMT_USER=
DST_RMT_CERT=

## LOG
DATE=$(date +%m-%d-%Y_%H-%M)Hs
LOG=$DST_PATH/LOG-BKP-$NAME-$DATE.log
echo "--------------------------------------------------------" | tee -a $LOG
echo "SCRIPT: $SCRIPT_NAME" | tee -a $LOG
echo "VERSION: $SCRIPT_VERSION" | tee -a $LOG
echo "INICIO: $DATE" | tee -a $LOG
echo "--------------------------------------------------------" | tee -a $LOG

# TYPE
TYPE="$1"
if [ "$#" -ne 1 ]; then
    echo "ERROR: Cantidad de Argumentos InvÃ¡dos." | tee -a $LOG
    exit 1
fi
if [[ "$TYPE" != "full" && "$TYPE" != "incremental" ]]; then
        echo "ERROR: Argumentos Invalidos" | tee -a $LOG
        echo "Ejecutar como <full> o <incremental>" | tee -a $LOG
        exit 1
fi

# CHECK DST PATH
if [ ! -d $DST_PATH ]; then 
        echo "Creando Directorio: $DST_PATH" | tee -a $LOG
        mkdir -p $DST_PATH 2>> $LOG 1>> $LOG
fi

# FULL
if [ "$TYPE" == "full" ]; then
        FILE_BACKUP=BKP-$NAME-$DATE-FULL.tar.gz
        echo "TIPO DE BACKUP: FULL" | tee -a $LOG
        echo "" | tee -a $LOG
        if [ -f $DST_PATH/$SNAR_BACKUP ]; then
                echo " Encontre SNAR. " | tee -a $LOG
                echo " Moviendo a: $DST_PATH/FULL-$DATE/" | tee -a $LOG
                mkdir $DST_PATH/FULL-$DATE/ 2>> $LOG 1>> $LOG
                mv $DST_PATH/$SNAR_BACKUP $DST_PATH/FULL-$DATE/ 2>> $LOG 1>> $LOG
                mv $DST_PATH/*.tar.gz $DST_PATH/FULL-$DATE/ 2>> $LOG 1>> $LOG
                #mv $DST_PATH/*.log  $DST_PATH/FULL-$DATE/ 2>> $LOG 1>> $LOG
                FLAG_SNAR_MOVED=1
                echo "" | tee -a $LOG
        fi
        echo " Ejecutando Backup" | tee -a $LOG
        tar --listed-incremental=$DST_PATH/$SNAR_BACKUP -cvpzf $DST_PATH/$FILE_BACKUP "$BACKUP/" 2>> $LOG 1>> $LOG
        # NAGIOS
        EC="$?"
fi

# INCREMENTAL
if [ "$TYPE" == "incremental" ]; then
        FILE_BACKUP=BKP-$NAME-$DATE-INCR.tar.gz
        echo "TIPO DE BACKUP: INCREMENTAL" | tee -a $LOG
        echo "" | tee -a $LOG
        if [ ! -f $DST_PATH/$SNAR_BACKUP ]; then 
                echo " ERROR: No Encontre Snar..." | tee -a $LOG
                exit 1
        fi
        echo " Ejecutando Backup" | tee -a $LOG
        tar --listed-incremental=$DST_PATH/$SNAR_BACKUP -cvpzf $DST_PATH/$FILE_BACKUP "$BACKUP/" 2>> $LOG 1>> $LOG
        # NAGIOS
        EC="$?"
fi

# NAGIOS
if [ "$DST_NAGIOS_EXIT_FILE" != "0" ]; then
        echo "" | tee -a $LOG
        echo "NAGIOS EXIT FILE" | tee -a $LOG
        echo " EXIT CODE: $EC" | tee -a $LOG
        echo "$EC" > $DST_NAGIOS_EXIT_FILE/$NAGIOS_EXIT_FILE
        ENDTIME=$(date +"%s")
        diff=$(($ENDTIME-$STARTTIME))
        echo " TIEMPO DEL PROCESO: $(($diff / 60)) MINUTOS Y $(($diff % 60)) SEGUNDOS." | tee -a $LOG > $DST_NAGIOS_EXIT_FILE/$NAGIOS_TIME_FILE
fi

# RSYNC
if [ "$DST_RMT_SERVER" != "0" ]; then
        echo "" | tee -a $LOG
        echo "REMOTE PROCESS" | tee -a $LOG
        echo " REMOTE SERVER: $DST_RMT_SERVER" | tee -a $LOG
        rsync --delete-before -avze "ssh -i $DST_RMT_CERT" $DST_PATH/ $DST_RMT_USER@$DST_RMT_SERVER:$DST_RMT_PATH 2>> $LOG 1>> $LOG
fi
