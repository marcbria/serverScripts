#!/bin/bash

#######################################################################
# Eliminación de los datos operativos de un diario concreto.  
# Crea una copia de seguridad completa salvo que se indique lo contrario,
# detiene los contenedores asociados y elimina la base de datos y archivos.
# La configuración y la estructura del sitio se mantienen intactas.
#
# Sintaxis:
#     sudo ./jDataRemove.sh jounralTag [nobackup]
#
# Parámetros:
#     journalTag      Identificador del diario cuyos datos se eliminarán.
#     nobackup        (opcional) Ejecuta la eliminación sin crear la copia.
#
# Autoría: Marc Bria
# Licencia: GPL
# Última modificación: 20/01/2025
#######################################################################

# Creates a backup of the journal.
# Removes running DB and files.
# Configs and structure are PRESERVED.

# Check if a journal name is provided as an argument
if [ $# -eq 0 ]; then
    echo "REMOVES files and DB for the specified journal (backups by default)."
    echo "ERROR: Missing argument with journal's name."
    echo "Usage: $0 <journalName> [nobackup]"
    exit 1
fi

journal=${1}

# Verify if is running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script needs sudo privileges. Run as follows: sudo ./$0 journalName [nobackup]"
    exit 1
fi

################################
## CONFIG VARIABLES
################################

# Setting local folders (destination):
journalFiles=/srv/volumes/files

# Variables commented (not set) will be ignored.
journalSite=/home/docker/sites/${journal}
journalDbDumps=/srv/backups/migration/${journal}
journalAll=/srv/volumes/all/${journal}
journalDb=/srv/volumes/db/${journal}
journalLogs=/srv/volumes/logs/${journal}
journalFilesPublic=${journalFiles}/public/${journal}
journalFilesPrivate=${journalFiles}/private/${journal}
journalFilesConfigs=${journalFiles}/config/old/${journal}


################################
## Backup all data.
################################

# Stops and removes the containers
cd $journalSite
docker compose stop
docker compose down

# Create a tarball of ALL data for this journal named YYYYMMDD-HHMM-journal.tgz
timestamp=$(date +%Y%m%d-%H%M)
bckDestination="/srv/backups/deleted"
mkdir "${bckDestination}/${journal}" -p
chmod 666 ${bckDestination} -R
backupFile="${bckDestination}/${journal}/${timestamp}-${journal}.tgz"

if [ "$2" == "nobackup" ]; then
	echo "NO BACKUP MODE FORCED!: Data will be removed WITHOUT making a BACKUP first."
else
	tar -czf $backupFile $journalSite $journalDbDumps $journalAll $journalDb $journalLogs $journalFilesPublic $journalFilesPrivate $journalFilesConfigs

	if [ $? -ne 0 ]; then
    	echo "ERROR: Backup creation failed!"
    	exit 1
	fi

	echo "Backup created at $backupFile"
fi

# Warning message
read -p "This will REMOVE all data for $journal. Are you sure you want to continue? [y/N] " confirm
if [[ $confirm != [yY] ]]; then
    echo "Operation cancelled."
    exit 1
fi

# Check if $journal folders are defined AND exists before deleting
folders=($journalDbDumps $journalAll $journalDb $journalLogs $journalFilesPublic $journalFilesPrivate $journalFilesConfigs)

for folder in "${folders[@]}"; do
    if [ ! -d "$folder" ]; then
        echo "ERROR: Folder $folder does not exist."
        exit 1
    fi
done

# Removes the specified folders
# rm -rf $journalSite
# rm -rf $journalDbDumps
rm -rf $journalDb
rm -rf $journalLogs
rm -rf $journalFilesPublic
rm -rf $journalFilesPrivate
# rm -rf $journalFilesConfigs
# rm -rf $journalAll

echo ">>>> DB and files for $journal were REMOVED. Config and siteStruture were preserved."
