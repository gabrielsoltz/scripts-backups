# scripts-backups

Scripts para generar Backups en Bash:

1. targz-backup.sh:

	- Generación de Backup con TAR y GZ
	- Escritura de Logging de Todo el proceso
	- Genera Backups Full o Incrementales, según con que parámetro se lo llame. 
	- En caso de generar un Full, mueve los antiguos incrementales en caso de haber a una nueva carpeta.
	- En caso de generar un Incremental, verifica que exista un full anterior. 
	- Modulo para habilitar RSYNC con otro servidor una vez finalizado el backup
	- Modulo para generar output para Nagios.
	
	Variables Necesarias:
	- NAME=<Nombre>
	- BACKUP=<Path Backup>
	- DST_PATH=<Path Destino>

	Ejemplo:
	 - NAME=SITE
	 - BACKUP=/var/www/html
	 - DST_PATH=/backup

	 Ejecución:
	./targz-backup.sh full or incremental

2. mysql-backup.sh:

	- Dump Mysql
	- Compresión Gzip
	- Encriptado con OpenSSL
	- Modulo para habilitar RSYNC con otro servidor una vez finalizado el backup
	- Modulo para generar output para Nagios.

	Variables Necesarias:
	MYSQL_DB=<base de datos>
	MYSQL_LOGINPATH=<login path de mysql>
	DST_PATH=<Path Destino>

	Ejemplo:
	 - MYSQL_DB=prod
	 - MYSQL_LOGINPATH=backup
	 - DST_PATH=/backup

	 Ejecución:
	./mysql-backup.sh