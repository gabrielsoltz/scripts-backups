# targz-backup

Script para generar Backups en Bash con las siguientes funcionalidades:

	- Generación de Backup con TAR y GZ
	- Escritura de Logging de Todo el proceso
	- Genera Backups Full o Incrementales, según con que parámetro se lo llame. 
	- En caso de generar un Full, mueve los antiguos incrementales en caso de haber a una nueva carpeta.
	- En caso de generar un Incremental, verifica que exista un full anterior. 
	- Modulo para habilitar RSYNC con otro servidor una vez finalizado el backup
	- Modulo para generar output para Nagios.
	
Para Ejecutar Backup:

- Configurar las variables dentro del script, las siguientes 3 son necesarias:
	NAME=<Nombre>
	BACKUP=<Path Backup>
	DST_PATH=<Path Destino>

	Ejemplo:
	NAME=SITE
	BACKUP=/var/www/html
	DST_PATH=/backup

./targz-backup.sh <full> or <incremental>
	
