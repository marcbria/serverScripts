#!/bin/bash
#######################################################################
# Database dump for a specific journal.  
# Stops the application container to avoid DB writes, generates and
# compresses the dump, maintains a historical archive and ensures that
# the symbolic link is present in the journal’s folder.
#
# Dumps the database of the specified journal.  
# 1. Stops the app container to avoid DB writing.  
# 2. Dumps the database into /srv/volumes/db-import/<journalName>.  
# 3. Compresses the dump and manages historical archives.  
# 4. Restarts the application container.  
#
# Syntax:
#     sudo ./jDbDump.sh <journalTag>
#
# Parameters:
#     journalTag      Name of the journal whose database will be dumped.
#
# Author: Marc Bria
# License: GPL
# Last modification: 17/12/2024
#######################################################################

# Check if a journal name is provided as an argument
if [ $# -eq 0 ]; then
    echo "BDdumps the DB data of the specified journal"
    echo "ERROR: Missing argument with journal's name."
    echo "Usage: $0 <journalName>"
    exit 1
fi

journal=${1}

# Verify if is running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script needs sudo privileges. Run as root or as follows 'sudo ./$0 journalName'"
    exit 1
fi

################################
## CONFIG VARIABLES
################################

# Setting dump destination folder:
dumpDestination="/srv/volumes/db-import/${journal}"
journalPath=/home/docker/sites/${journal}


################################
## DBdumps the DB data.
################################

# Stops the app container (to be sure nobody writes in the DB).
cd $journalPath
docker compose stop app

source .env 

# Destination file will be named as YYYYMMDD-HHMM-journal.tgz
timestamp=$(date +%Y%m%d-%H%M)

# Ensures backup folder exists and is linked in the site's folder:
mkdir "${dumpDestination}" -p
ln -s "${dumpDestination}" "${journalPath}/volumes/db-import"

# Creates the historic folder:
mkdir "${dumpDestination}/history" -p
chmod 666 ${dumpDestination} -R
dumpFile="${dumpDestination}/${timestamp}-${journal}.sql"

# If any, moves existing compressed-dumps to the historic folder:
mv ${dumpDestination}/*.gz ${dumpDestination}/history/ 2>/dev/null

# Dump of the DB container:
docker exec -it ojs_db_${journal} bash -c \
"mysqldump --default-character-set=utf8mb4 -u${MYSQL_USER} -p${MYSQL_PASSWORD} --databases $MYSQL_DATABASE" > "${dumpFile}"

# Fix charset to be utf8mb4:
sed -i 's/CHARSET=latin1/CHARSET=utf8mb4/g' ${dumpFile}

# Compress and remove original dump:
gzip ${dumpFile}

# Raises it again:
docker compose up -d

if [ $? -ne 0 ]; then
   	echo "ERROR: DBdump creation failed!"
   	exit 1
fi

echo ">>>> ALL DB data for $journal was DUMPED at:"
echo "     -  $dumpFile"
