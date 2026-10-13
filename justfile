# Justfile

# Default target to show available targets
_default:
    @just -l

# Docker: Test HTTP/HTTPS proxy connectivity for Packagist (using docker)
hProxyTest:
    @echo "Docker: Tests HTTP/HTTPS proxy connectivity"
    docker run --rm \
        -v "{{justfile_directory()}}":/app \
        -w /app \
        php:cli php hProxyTest.php

# Docker: Transfer a Docker image from a remote server to the local server
dTransferImage remoteHost imageName:
    @echo "Docker: Transfers a Docker image '{{imageName}}' from '{{remoteHost}}' to the local server"
    ./dTransferImage.sh {{remoteHost}} {{imageName}}

# Journal: Backup all data for the specified journal
jBackup JurnalTag:
    @echo "Journal: Creates a full backup of all data for the journal '{{JurnalTag}}'"
    sudo ./jBackup.sh {{JurnalTag}}

# Journal: Dump the database of the specified journal
jDumpDB JurnalTag:
    @echo "Journal: Dumps the database of the journal '{{JurnalTag}}'"
    sudo ./jDumpDB.sh {{JurnalTag}}

# Journal: Fully remove all data for the specified journal (backupMode: backup|nobackup, checkMode: check|nocheck)
jFullRemove JurnalTag backupMode checkMode:
    @echo "Journal: Fully removes all data for the journal '{{JurnalTag}}' (backup mode: '{{backupMode}}', check mode: '{{checkMode}}')"
    sudo ./jFullRemove.sh {{JurnalTag}} {{backupMode}} {{checkMode}}

# Journal: Remove DB and files for the specified journal (backupMode: backup|nobackup)
jDataRemove JurnalTag backupMode:
    @echo "Journal: Removes DB and files for the journal '{{JurnalTag}}' (backup mode: '{{backupMode}}')"
    sudo ./jDataRemove.sh {{JurnalTag}} {{backupMode}}

# Multiple: Calculates and display the space occupied for each journal
spaceUsage journalList:
    @echo "Multiple: Calculates and displays space used by multiple journals in the list"
    sudo ./mSpaceUsage.sh {{journalList}}

# DEPRECATED CAR-Migration: Gets all the journals listed in the fileParam from the remote server
_getAllVols journalList:
    @echo "CAR-Migration: Fetches all journal volumes listed in the file from the remote server"
    sudo ./getAllVols.sh {{journalList}}

# DEPRECATED CAR-Migration: Gets the volumes of the specified journal from the remote server
_getRemoteVols journal:
    @echo "CAR-Migration: Fetches volumes of the specified journal from the remote server"
    sudo ./getRemoteVol.sh {{journal}}

