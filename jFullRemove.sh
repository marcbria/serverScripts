#!/bin/bash

#######################################################################
# Removes all data associated with a specific journal.  
# Stops and deletes containers, optionally creates a full backup, and
# removes every related folder.
#
# Fully removes all data for the specified journal.  
# 1. Stops and removes containers.  
# 2. Optionally creates a full backup unless "nobackup" is provided.  
# 3. Checks folder existence unless "nocheck" is provided.  
# 4. Deletes all associated data folders.  
#
# Syntax:
#     sudo ./jFullRemove.sh <JurnalTag> [nobackup] [nocheck]
#
# Parameters:
#     JurnalTag        Tag of the journal to be removed.  
#     nobackup         Skip backup creation.  
#     nocheck          Skip existence checks before deleting folders.  
#
# Author: Marc Bria
# License: GPL
# Last modification: 21/02/2025
#######################################################################

# Check if a journal name is provided as an argument
if [ $# -eq 0 ]; then
    echo "REMOVES all data for the specified journal"
    echo "ERROR: Missing argument with journal's name."
    echo "Usage: $0 <journalName> [nobackup] [nocheck]"
    exit 1
fi

journal=${1}

# Verify if is running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script needs sudo privileges. Run as follows 'sudo ./deleteJournal.sh journalName [nobackup]'"
    exit 1
fi

################################
## CONFIG VARIABLES
################################

# Setting local folders (destination):
journalFiles=/srv/volumes/files

# Variables commented (not set) will be ignored.
journalSite=/home/docker/sites/${journal}
journalDbDumps=/srv/backups/${journal}
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

if [ "$3" == "nocheck" ]; then
    echo "NO CHECK MODE FORCED!: Folders will be removed without checking if they exist first."
else 


	# Check if $journal folders are defined AND exists before deleting
	folders=($journalDbDumps $journalAll $journalDb $journalLogs $journalFilesPublic $journalFilesPrivate $journalFilesConfigs)

	for folder in "${folders[@]}"; do
    	if [ ! -d "$folder" ]; then
        	echo "ERROR: Folder $folder does not exist."
        	exit 1
    	fi
	done
fi

# Removes the specified folders
rm -rf $journalSite
rm -rf $journalDbDumps
rm -rf $journalDb
rm -rf $journalLogs
rm -rf $journalFilesPublic
rm -rf $journalFilesPrivate
rm -rf $journalFilesConfigs
rm -rf $journalAll

echo ">>>> ALL data for $journal was REMOVED!"
