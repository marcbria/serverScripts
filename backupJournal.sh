#!/bin/bash

# Check if a journal name is provided as an argument
if [ $# -eq 0 ]; then
    echo "BACKUPS all data for the specified journal"
    echo "ERROR: Missing argument with journal's name."
    echo "Usage: $0 <journalName> [nobackup]"
    exit 1
fi

journal=${1}

# Verify if is running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script needs sudo privileges. Run as follows 'sudo ./backupJournal.sh journalName [nobackup]'"
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

echo ">>>> ALL data for $journal was BACKUP!"
