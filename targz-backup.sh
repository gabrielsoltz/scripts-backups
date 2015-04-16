#!/bin/bash
########################################################################################################################
# TARGZ-BACKUP
########################################################################################################################
SCRIPT_NAME="TARGZ-BACKUP"
SCRIPT_DESCRIPTION="Backp Script, with tar.gz, rsync, full or incremental mode and nagios output."
SCRIPT_VERSION="1.0"
SCRIPT_AUTHOR="Gabriel Soltz"
SCRIPT_CONTACT="thegaby@gmail.com"
SCRIPT_DATE="15-04-2015"
SCRIPT_GIT="https://github.com/gabrielsoltz/targz-backup"
SCRIPT_WEB="www.3ops.com"
########################################################################################################################

# VARIABLES
NAME=
BACKUP=
DST_PATH=
SNAR_BACKUP=BKP-$NAME.snar

# VARIABLES PARA GENERAR RSYNC. (DST_RMT_SERVER=0 LO DESHABILITA)
DST_RMT_SERVER=0
DST_RMT_PATH=
DST_RMT_USER=
DST_RMT_CERT=

# OUTPUT FOR: check_nagios_targz_backup.sh (DST_NAGIOS_EXIT_FILE=0 LO DESHABILITA)
DST_NAGIOS_EXIT_FILE=$DST_PATH
NAGIOS_EXIT_FILE=BKP-$NAME.exit
NAGIOS_TIME_FILE=BKP-$NAME-TIME.exit
STARTTIME=$(date +"%s")

## LOG
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DATE=$(date +%m-%d-%Y_%H-%M)Hs
LOG=$DIR/LOG-BKP-$NAME-$DATE.log
echo "--------------------------------------------------------" | tee -a $LOG
echo "SCRIPT: $SCRIPTNAME" | tee -a $LOG
echo "VERSION: $VERSION" | tee -a $LOG
echo "INICIO: $DATE" | tee -a $LOG
echo "--------------------------------------------------------" | tee -a $LOG

# TYPE
TYPE="$1"
if [ "$#" -ne 1 ]; then
    echo "ERROR: Cantidad de Argumentos Inválidos." | tee -a $LOG
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
	if [ -f $DST_PATH/$SNAR_BACKUP ]; then
		echo " Encontre SNAR. " | tee -a $LOG
		echo " Moviendo a: $DST_PATH/FULL-$DATE/" | tee -a $LOG
		mkdir $DST_PATH/FULL-$DATE/ 2>> $LOG 1>> $LOG
		mv $SNAR_BACKUP $DST_PATH/FULL-$DATE/ 2>> $LOG 1>> $LOG
		mv $DST_PATH/*.tar.gz $DST_PATH/FULL-$DATE/ 2>> $LOG 1>> $LOG
		mv $DST_PATH/*.log $DST_PATH/FULL-$DATE/ 2>> $LOG 1>> $LOG
		FLAG_SNAR_MOVED=1
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
	if [ ! -f $DST_PATH/$SNAR_BACKUP ]; then 
		echo " ERROR: No Encontre Snar..." | tee -a $LOG
		exit 1
	fi
	echo " Ejecutando Backup" | tee -a $LOG
	tar --listed-incremental=$DST_PATH/$SNAR_BACKUP -cvpzf $DST_PATH/$FILE_BACKUP "$BACKUP/" 2>> $LOG 1>> $LOG
	# NAGIOS
	EC="$?"
fi

# RSYNC
if [ "$DST_RMT_SERVER" != "0" ]; then
	echo "" | tee -a $LOG
	echo "REMOTE PROCESS" | tee -a $LOG
	echo " REMOTE SERVER: $DST_RMT_SERVER" | tee -a $LOG
	rsync -avze "ssh -i $DST_RMT_CERT" $DST_PATH/ $DST_RMT_USER@$DST_RMT_SERVER:$DST_RMT_PATH 2>> $LOG 1>> $LOG
fi

# NAGIOS
if [ "$DST_NAGIOS_EXIT_FILE" != "0" ]; then
	echo "" | tee -a $LOG
	echo "NAGIOS EXIT FILE" | tee -a $LOG
	echo " EXIT CODE: $EC" | tee -a $LOG
	echo "$EC" > $DST_NAGIOS_EXIT_FILE/$NAGIOS_EXIT_FILE
	ENDTIME=$(date +"%s")
	diff=$(($ENDTIME-$STARTTIME))
	echo " TIEMPO DEL PROCESO: $(($diff / 60)) MINUTOS Y $(($diff % 60)) SEGUNDOS."  | tee -a $LOG
	echo " TIEMPO DEL PROCESO: $(($diff / 60)) MINUTOS Y $(($diff % 60)) SEGUNDOS." > $DST_NAGIOS_EXIT_FILE/$NAGIOS_TIME_FILE
fi