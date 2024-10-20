#!/bin/bash

LOG_DIR="/LOG"
BACKUP_DIR="/BACKUP"

PERCENT=70   # Default filling percent (70%)
NUM_FILES=$(ls -1 /LOG | wc -l) # Default n last files to archive (None)

while [ -n "$1" ] # While not first arg
do
case "$1" in
-p) PERCENT="$2"
if [[ ! "$PERCENT" =~ ^[0-9]+$ || "$PERCENT" -lt 0 || "$PERCENT" -gt 100 ]] then # Check if percent is number
        echo "Error: Bad option for -p. It must num (0 <= num <= 100)"
        exit 1
fi
shift;;
-n) NUM_FILES="$2"
if [[ ! "$NUM_FILES" =~ ^[0-9]+$ || "$NUM_FILES" -le 0 ]] then # Check if percent is number
        echo "Error: Bad option for -n. It must be num greater, than 0"
        exit 1
fi
shift;;
*) echo "$1 is unknown option";;
esac
shift # Shift args line
done

CUR_USAGE=$(df "$LOG_DIR" --output=pcent | tail -1 | tr -d '%',' ') # Gets two lines, extracts the last and delets char ' ', '%'
echo "Current disk usage is $CUR_USAGE%"
echo "Threshold for archiving: $PERCENT%"
echo "Number of files to archive: $NUM_FILES"
if [ "$CUR_USAGE" -le "$PERCENT" ] # Checks if CUR_USAGE <= PERCENT, then exit
then
        echo "Exiting..."
        exit 0
fi

if [ "$NUM_FILES" -le 0 ] # Check if there is files to archive
then
        echo "There is no files to archive. Exiting..."
        exit 0
fi

echo "Usage exceeds the threshold, archiving files..."
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
TAR_PATH="$BACKUP_DIR/log_backup_$TIMESTAMP.tar.gz"

FILES_TO_TAR=$(ls -1t "$LOG_DIR" | tail -n "$NUM_FILES")

tar -czf "$TAR_PATH" -C "$LOG_DIR" $FILES_TO_TAR
echo "$FILES_TO_TAR" | xargs -I {} rm "$LOG_DIR/{}" # Применяем команду rm к списку файлов подставляя путь до них
echo "Files archived to $TAR_PATH and deleted from $LOG_DIR"
