#!/bin/bash

# Usage:
# ./backup.sh -h <host> [-p <port>] -u <username> -w <password> -d <database> [-o <output_dir>]

# Default values
DEFAULT_PORT="5432"
DEFAULT_BACKUP_DIR="/workdir/backup"

# Parse command-line arguments
while getopts ":h:p:u:w:d:o:" opt; do
  case $opt in
    h) HOST=$OPTARG ;;
    p) PORT=$OPTARG ;;
    u) USERNAME=$OPTARG ;;
    w) PASSWORD=$OPTARG ;;
    d) DATABASE=$OPTARG ;;
    o) BACKUP_DIR=$OPTARG ;;
    \?) echo "Invalid option: -$OPTARG" >&2
        exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2
       exit 1 ;;
  esac
done

# Set default values if not provided
PORT=${PORT:-$DEFAULT_PORT}
BACKUP_DIR=${BACKUP_DIR:-$DEFAULT_BACKUP_DIR}

# Check if all required arguments are provided
if [ -z "$HOST" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$DATABASE" ]; then
  echo "Usage: $0 -h <host> [-p <port>] -u <username> -w <password> -d <database> [-o <output_dir>]"
  exit 1
fi

# Create the backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create backup filename with timestamp
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
BACKUP_FILE="$BACKUP_DIR/backup-$DATABASE-$TIMESTAMP.sql"

# Inform the user about the backup process
echo "Backup of database '$DATABASE' is starting..."
echo "Host: $HOST, Port: $PORT, User: $USERNAME"
echo "Backup file will be saved in: $BACKUP_FILE"

# Perform the backup
PGPASSWORD=$PASSWORD pg_dump -h $HOST -p $PORT -U $USERNAME -d $DATABASE --inserts > "$BACKUP_FILE"

# Check if the backup was successful
if [ $? -eq 0 ]; then
  echo "Backup created successfully: $BACKUP_FILE"

  # Compress the backup file
  gzip "$BACKUP_FILE"
  echo "Backup file compressed to: $BACKUP_FILE.gz"
else
  echo "Backup failed!"
  exit 1
fi

# Clean up old backups (older than 3 days)
find "$BACKUP_DIR" -name "backup-$DATABASE-*.sql.gz" -type f -mtime +3 -exec rm -f {} \;

echo "Old backups older than 3 days have been deleted."
