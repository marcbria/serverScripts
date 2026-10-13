#!/bin/bash

# DBdumps the DB data from the journal specified at $JOURNAL variable.
# 1. Stops the app container to avoid DB writing.
# 2. Dumps the DB in the $dumpDestination folder (/srv/volumes/db-import/<$JOURNAL>)
# 3. Compresses the BD and stores it at sql.gz.
# 4. Raises the app container again.


######################################
## CHECK PERMISSIONS, VARS AND PARAMS
######################################

# Verify if is running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script needs sudo privileges. Run as root or as follows 'sudo ./$0'"
    exit 1
fi

# Check if the journal variable is provided
if [ -z "${JOURNAL+x}" ] || [ -z "$JOURNAL" ]; then
    echo "ERROR: variable $JOURNAL is not set."
    echo "Usage: $0"
    exit 1
fi


################################
## CONFIG VARIABLES
################################

# Setting dump destination folder:
dumpDestination="/srv/volumes/db-import/${JOURNAL}"
journalPath=/home/docker/sites/${JOURNAL}


################################
## DBdumps the DB data.
################################

# Stops the app container (to be sure nobody writes in the DB)
cd $journalPath
source .env
docker compose stop app

# Create a gzip with the DB data of this journal named YYYYMMDD-HHMM-journal.sql.gz
timestamp=$(date +%Y%m%d-%H%M)

# Creates the historic folder:
mkdir "${dumpDestination}/history" -p
chmod 666 ${dumpDestination} -R
dumpFile="${dumpDestination}/${timestamp}-${JOURNAL}.sql"

# If any, moves existing compressed-dumps to the historic folder:
mv ${dumpDestination}/*.gz ${dumpDestination}/history/ 2>/dev/null

# Dump of the DB container:
docker exec ojs_db_${JOURNAL} bash -c \
"mysqldump --default-character-set=utf8mb4 -u${MYSQL_USER} -p${MYSQL_PASSWORD} --databases $MYSQL_DATABASE" > "${dumpFile}"

# Fix charset to ensure utf8mb4:
sed -i 's/CHARSET=latin1/CHARSET=utf8mb4/g' ${dumpFile}

# Compress, removing the original dump:
gzip ${dumpFile}

# If was stoped, raises it again:
docker compose up -d

if [ $? -ne 0 ]; then
   	echo "ERROR: DBdump creation failed!"
   	exit 1
else
    echo ">>>> DB data for ${JOURNAL} was DUMPED at: ${dumpFile}"
fi
