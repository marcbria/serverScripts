#!/bin/bash

# Check if a journal list file is provided as an argument
if [ $# -eq 0 ]; then
    echo "Calculates and display the space occupied for each journal"
    echo "Usage: $0 <journalListFile>"
    echo "Example: $0 ./configs/journals.lst"
    exit 1
fi

journalListFile=$1

# Check if the file exists
if [ ! -f "$journalListFile" ]; then
    echo "The file $journalListFile does not exist."
    exit 1
fi

# Size limits in MB
minSize=10
maxSize=1000

# Function to get the size of a directory in MB
getDirectorySize() {
    local dir="$1"
    # Check if the directory exists before getting its size
    if [ -d "$dir" ]; then
        # sudo du -smL "$dir" | cut -f1
 	sudo du -smL "$dir" 2>> analyze-errors.log | cut -f1
    else
        echo "0"
    fi
}

# Function to print an output line with color based on size
printOutputLine() {
    local journal="$1"
    local size="$2"
    local volumes="$3 MB"
    local backups="$4 MB"

    if [ "$size" -le "$minSize" ]; then
        color=$(tput setaf 7)  # White
    elif [ "$size" -le "$maxSize" ]; then
        color=$(tput setaf 3)  # Yellow
    else
        color=$(tput setaf 1)  # Red
    fi

    size="$size MB"

    printf "%-20s %s | %-10s | %-10s | %-10s | %s\n" "$journal" "$color" "$size" "$volumes" "$backups" "$(tput sgr0)"
}

# Header of the output
printf "%-20s  | %-10s | %-10s | %-10s |\n" "Journal" "Total Size" "Volume" "Backup"

# Calculate and display the space occupied for each journal
while IFS= read -r journal; do
    volumeSize=$(getDirectorySize "/srv/volumes/all/${journal}")
    backupSize=$(getDirectorySize "/srv/backups/${journal}")
    totalSize=$((volumeSize + backupSize))
    printOutputLine "$journal" "$totalSize" "$volumeSize" "$backupSize"
done < "$journalListFile"

