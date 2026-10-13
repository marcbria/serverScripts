#!/bin/bash

####################
# getRemoteVolume
###################

# Check if a list of journals is provided as an argument
if [ $# -eq 0 ]; then
    echo "Gets all the journals listed in the fileParam from the remote server"
    echo "Usage: $0 ./configs/<listOfJournals>"
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

mkdir ./logs/${timestamp}

# Read the file line by line and execute the command
while IFS= read -r line || [ -n "$line" ]; do
    ./getRemoteVol.sh "$line" 2>&1 | tee ./logs/${timestamp}/${line}.log
    grep "error" ./logs/${timestamp}/${line}.log >> ./logs/${timestamp}/errors-${line}.lst
    sleep 30
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

logFile="./logs/ERRORS-${timestamp}.log"

{
    echo "Journal List File: $listOfJournals"
    echo -e "\nExecution time: ${executionTime} seconds"
    echo "   - Hours: ${hours}"
    echo "   - Minutes: ${minutes}"
    echo "   - Seconds: ${seconds}"
} | tee -a "$logFile"

grep "error" ./logs/${timestamp}/*.log >> ./logs/ERRORS-${timestamp}.log
