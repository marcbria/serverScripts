#!/bin/bash

# Script to create ZFS snapshots for datasets matching a given parameter.
# Usage: ./snapshotNow.sh <journalName>
# If no parameter is provided, it displays the correct syntax.

# Variables
inputParam=$1          # First parameter passed to the script (e.g., "journalName")
timestamp=$(date "+%Y-%m-%d_%H:%M:%S")  # Current date and time in the specified format
snapshotSuffix="_manual" # Suffix to append to the snapshot name

# Check if a parameter was provided
if [ -z "$inputParam" ]; then
    echo "Syntax: $0 <prefix>"
    echo "Example: $0 myApp"
    exit 1
fi

# List of datasets to check
datasets=(
    "srv/volumes"
    "srv/volumes/db"
    "srv/volumes/files"
    "srv/volumes/logs"
)

# Loop through datasets and create snapshots
for dataset in "${datasets[@]}"; do
    snapshotName="${dataset}@${inputParam}_${timestamp}${snapshotSuffix}"
    echo "Creating snapshot: $snapshotName"
    zfs snapshot "$snapshotName"
done

echo "Snapshot complete for $inputParam."
