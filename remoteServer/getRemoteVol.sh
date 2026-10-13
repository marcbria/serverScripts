#!/bin/bash

# Check if a journal name is provided as an argument
if [ $# -eq 0 ]; then
    echo "Pulls all the volumes of the specified journal from the remote server"
    echo "ERROR: Missing argument with journal's name."
    echo "Usage: $0 <journal>"
    exit 1
fi

journal=${1:-"demo"}

echo "Gets all the volumes of the specified journal from the remote server"

# Verificar si se ejecuta con sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script needs sudo privileges. Run as follows 'sudo ./getRemoteVol.sh'"
    exit 1
fi

startTime=$(date +%s)

################################
## CONFIG VARIABLES
################################

# Remote user (need the proper privileges in the remote machine)
remoteUsr=marc

# IMPORTANT: Before running the script you need to exchange the keys.
# After this, indicate where is your private key to rsync without pwds.
privateKeyPath=/home/${remoteUsr}/.ssh/id_rsa

# Setting remote folders (source)
srcDbDumps=/srv/backup/duplicati/db-dump/*${journal}-*
srcAll=/srv/volumes/${journal}
srcDb=/srv/volumes/${journal}/db
srcLogs=/srv/volumes/${journal}/logs
srcFiles=/srv/volumes/${journal}/files
srcFilesPublic=/srv/volumes/${journal}/public
srcFilesPrivate=/srv/volumes/${journal}/private
srcFilesConfigs=/srv/volumes/${journal}/config

# Setting local folders (destination):
destFiles=/srv/volumes/files 			

# Variables commented (not set) will be ignored.
destDbDumps=/srv/backups/migration/${journal}
destAll=/srv/volumes/all/${journal}
# destDb=/srv/volumes/db/${journal}
# destLogs=/srv/volumes/logs/${journal}
destFilesPublic=${destFiles}/public/${journal}
destFilesPrivate=${destFiles}/private/${journal}
destFilesConfigs=${destFiles}/config/old/${journal}


################################
## Running the data move
################################

# Debug:
## rm $destDbDumps/${journal} -Rf
## rm $destDb/${journal} -Rf
## rm $destLogs/${journal} -Rf
## rm $destFiles/${journal} -Rf
## rm $destConfigs/${journal} -Rf
## rm $destAll/${journal} -Rf

echo "Ensures the required folder structure exists"
mkdir -p ${destDbDumps}        > /dev/null 2>&1
mkdir -p ${destAll}            > /dev/null 2>&1
mkdir -p ${destDb}             > /dev/null 2>&1
mkdir -p ${destLogs}           > /dev/null 2>&1
mkdir -p ${destFiles}          > /dev/null 2>&1
mkdir -p ${destFilesPublic}    > /dev/null 2>&1
mkdir -p ${destFilesPrivate}   > /dev/null 2>&1
mkdir -p ${destFilesConfigs}   > /dev/null 2>&1

# Commons folder: Run once
# rsync -avzh -e "ssh -i /home/marc/.ssh/id_rsa" --rsync-path="sudo rsync" marc@adacar:/home/dojo/sites/common/ /home/docker/sites/common -a

echo "Go in..."
# Pulls DB Dumps
if [ -n "$destDbDumps" ]; then
	echo "Running..."
	echo "--> Rsyncing: ${srcDbDumps}"
	rsync -avzh -e "ssh -i ${privateKeyPath}" --rsync-path="sudo rsync" ${remoteUsr}@adacar:${srcDbDumps} ${destDbDumps}
	rm -Rf ${destAll}/migration
	ln -s ${destDbDumps} ${destAll}/migration
	# Removes al dump files except the newer one:
    cd ${destDbDumps}
    latestDump=$(ls -1t | head -n 1)
    ls -1 | grep -v "$latestDump" | xargs rm -f 
    # Add general fixes:
    cp /home/marc/serverMigration/dbFix/* . -a
    # Sets permissions for mysql:mysql user and group
    chown 999:999 ${destDbDumps}/ -Rh
    find ${destDbDumps} -type d -exec chmod 0755 {} \;
    find ${destDbDumps} -type f -exec chmod 0755 {} \;
fi

# Pulls the db/Log/files
if [ -n "$destDb" ]; then
	echo "--> Rsyncing: ${srcDb}"
	rsync -avzh -e "ssh -i ${privateKeyPath}" --rsync-path="sudo rsync" ${remoteUsr}@adacar:${srcDb}/ ${destDb}
	unlink ${destAll}/db
	ln -s ${destDb} ${destAll}/db
    # Sets permissions for mysql:mysql user and group
    chown 999:999 ${destAll}/db/ -R
    find ${destAll}/db -type d -exec chmod 0755 {} \;
    find ${destAll}/db -type f -exec chmod 0644 {} \;
fi

# Pulls the logs
if [ -n "$destLogs" ]; then
	echo "--> Rsyncing ${srcLogs}"
	rsync -avzh -e "ssh -i ${privateKeyPath}" --rsync-path="sudo rsync" ${remoteUsr}@adacar:${srcLogs}/ ${destLogs}
	unlink ${destAll}/logs
	ln -s ${destLogs} ${destAll}/logs
    # Sets permissions for apache:apache user and group
    chown 100:101 ${destAll}/logs/ -R
    find ${destAll}/logs -type d -exec chmod 0755 {} \;
    find ${destAll}/logs -type f -exec chmod 0644 {} \;
fi

# Pulls the Public Files
if [ -n "$destFilesPublic" ]; then
	echo "--> Rsyncing ${srcFilesPublic}"
	echo "rsync -avzh -e \"ssh -i ${privateKeyPath}\" --rsync-path=\"sudo rsync\" ${remoteUsr}@adacar:${srcFilesPublic}/ ${destFilesPublic}"
	rsync -avzh -e "ssh -i ${privateKeyPath}" --rsync-path="sudo rsync" ${remoteUsr}@adacar:${srcFilesPublic}/ ${destFilesPublic}
	unlink ${destAll}/public
	ln -s ${destFilesPublic} ${destAll}/public
    chown 100:101 ${destAll}/public/ -Rh
    chmod 750 ${destAll}/public/ -Rh
    find ${destAll}/public -type d -exec chmod 0755 {} \;
    find ${destAll}/public -type f -exec chmod 0644 {} \;
fi

# Pulls the Private Files
if [ -n "$destFilesPrivate" ]; then
	echo "--> Rsyncing ${srcFilesPrivate}"
	rsync -avzh -e "ssh -i ${privateKeyPath}" --rsync-path="sudo rsync" ${remoteUsr}@adacar:${srcFilesPrivate}/ ${destFilesPrivate}
	unlink ${destAll}/private
	ln -s ${destFilesPrivate} ${destAll}/private
    chown 100:101 ${destAll}/private/ -R
    find ${destAll}/private -type d -exec chmod 0750 {} \;
    find ${destAll}/private -type f -exec chmod 0640 {} \;
fi

# Pulls the Config Files
if [ -n "$destFilesPrivate" ]; then
	echo "--> Rsyncing ${srcFilesConfig}"
	rsync -avzh -e "ssh -i ${privateKeyPath}" --rsync-path="sudo rsync" ${remoteUsr}@adacar:${srcFilesConfigs}/ ${destFilesConfigs}
	# unlink ${destAll}/config
	# ln -s ${destFilesConfigs} ${destAll}/config
fi

endTime=$(date +%s)

# Calculates the elapsed time
elapsedTime=$((endTime - startTime))
formattedTime=$(date -u -d @"$elapsedTime" +'%H:%M:%S')

echo ">>>> The transfer of the volumes of $journal took: $formattedTime"
