#!/bin/bash

#######################################################################
# Executes an SQL file inside the database container of a given journal.
# Optionally creates a ZFS snapshot before applying the SQL changes.
#
# Behaviour:
#   1. Validates parameters and checks sudo privileges.
#   2. Loads journal-specific environment variables from its .env file.
#   3. Optionally creates a ZFS snapshot when "1" is passed as third arg.
#   4. Executes the SQL file inside the journal's DB container.
#
# Syntax:
#     sudo ./jRunSQL.sh <JurnalTag> <sqlFilePath> [snapshot]
#
# Parameters:
#     JurnalTag      Tag of the journal where the SQL will be executed.
#     sqlFilePath    Path to the SQL file to be applied.
#     snapshot       Optional: "1" to create a ZFS snapshot before running SQL.
#
# Author: Marc Bria
# License: GPL
# Last modification: 20/01/2025
#######################################################################

# Check if journal name and SQL file path are provided as arguments
if [ $# -lt 2 ]; then
    echo "Runs a SQL file in the specified journal"
    echo "ERROR: Missing arguments."
    echo "Usage: $0 <journalName> <sqlFilePath> [snapshot]"
    exit 1
fi

journal=${1}
sqlFilePath=${2}
snapshot=${3:-0}  # Optional parameter, default to 0 if not provided

# Verify if the SQL file exists
if [ ! -f "$sqlFilePath" ]; then
    echo "ERROR: The SQL file '$sqlFilePath' does not exist."
    exit 1
fi

# Verify if the script is running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script needs sudo privileges. Run as root or as follows 'sudo $0 <journalName> <sqlFilePath>'"
    exit 1
fi


################################
## CONFIG VARIABLES
################################

sqlPath="/home/marc/serverMigration/dbRun"
journalPath=/home/docker/sites/${journal}

################################
# Environment variables
################################

# Loading from .env
if [ -f "$journalPath/.env" ]; then
    source "$journalPath/.env"
else
    echo "ERROR: .env file not found at $journalPath"
    exit 1
fi


################################
# ZFS Snapshot (shit happens)
################################

if [ "$snapshot" -eq 1 ]; then
	./zfs/snapshotNow.sh ${journal}
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create ZFS snapshot."
        exit 1
    fi
    echo "ZFS snapshot created successfully."
fi


################################
## Runs the SQL file query
################################

# Run the SQL file in the MySQL container
containerName="ojs_db_${journal}"

docker exec -i "$containerName" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" ojs < "$sqlFilePath"

if [ $? -eq 0 ]; then
    echo "SQL script '$sqlFilePath' executed successfully in journal '$journal'."
else
    echo "ERROR: Failed to execute SQL script '$sqlFilePath' in journal '$journal'."
    exit 1
fi

