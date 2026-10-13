#!/bin/bash

# Check if a list of journals is provided as an argument
if [ $# -eq 0 ]; then
    echo "Gets all the journals listed in the fileParam from the remote server"
    echo "Usage: $0 ./configs/<listOfJournals>.lst"
    exit 1
fi

listOfJournals=$1

# Check if the file exists
if [ ! -f "$listOfJournals" ]; then
    echo "The file $listOfJournals does not exist."
    exit 1
fi

# Record the start time
startTime=$(date +%s)
timestamp=$(date +%Y%m%d-%H%M)

numJournals=0

mkdir ./logs/${timestamp}

# Read the file line by line and execute the command
while IFS= read -r line || [ -n "$line" ]; do
    echo "Deleting DB for: $line"
    rm -Rf /home/docker/sites/$line/volumes/db/* "$line" 2>&1 | tee -a ./logs/deleteDB-${timestamp}.log
    ((numJournals++))
done < "$listOfJournals"

echo "=============================="
echo "==     Process completed    =="
echo "=============================="

# Record the end time
endTime=$(date +%s)

# Calculate the execution time
executionTime=$((endTime - startTime))
hours=$((executionTime / 3600))
minutes=$(( $((executionTime % 3600)) / 60))
seconds=$((executionTime % 60))

logFile="./logs/deleteDB-${timestamp}.log"

{
    echo "Journal List File: $listOfJournals"
    echo "Journals processed: $numJournals"
    echo -e "\nExecution time: ${executionTime} seconds"
    echo "   - Hours: ${hours}"
    echo "   - Minutes: ${minutes}"
    echo "   - Seconds: ${seconds}"
} | tee -a "$logFile"
