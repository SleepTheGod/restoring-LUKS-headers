#!/bin/bash

set -e

# Function: Display usage instructions
usage() {
  echo "LUKS Manager Script - Manage LUKS encryption with ease."
  echo "======================================================="
  echo "Usage: sudo $0 [OPTION]"
  echo ""
  echo "Options:"
  echo "  --usage        Show this usage information"
  echo "  --add-nuke     Add a nuke key to your LUKS device"
  echo "  --backup       Backup the LUKS header securely"
  echo "  --restore      Restore the LUKS header from a backup"
  echo ""
  echo "This script will automatically detect your LUKS device."
  echo "Ensure to run this script as root for proper functionality."
  exit 0
}

# Check for root privileges
if [ "$(id -u)" -ne 0; then
  echo "Error: This script must be run as root."
  exit 1
fi

# Check for required tools
for tool in cryptsetup openssl blkid; do
  if ! command -v "$tool" &>/dev/null; then
    echo "Error: $tool is not installed."
    exit 1
  fi
done

# Detect LUKS device automatically
detect_luks_device() {
  LUKS_DEVICE=$(blkid | grep -i luks | awk -F: '{print $1}' | head -n 1)
  if [ -z "$LUKS_DEVICE" ]; then
    echo "Error: No LUKS device detected on this system."
    exit 1
  fi
}

# Set dynamic variables
BACKUP_LOCATION="/var/backups/luks"
HEADER_BACKUP="luksheader.back"
ENCRYPTED_BACKUP="${HEADER_BACKUP}.enc"
NUKE_PASSWORD="NukeKey123" # Secure default nuke key

# Ensure backup location exists
mkdir -p "$BACKUP_LOCATION"

# Functions
add_nuke_key() {
  echo "Adding nuke key..."
  apt-get update && apt-get install -y cryptsetup-nuke-password
  echo -n "$NUKE_PASSWORD" | cryptsetup luksAddNukeKey $LUKS_DEVICE
  echo "Nuke key added successfully."
}

backup_header() {
  echo "Backing up LUKS header..."
  cryptsetup luksHeaderBackup --header-backup-file $HEADER_BACKUP $LUKS_DEVICE
  openssl enc -aes-256-cbc -salt -in $HEADER_BACKUP -out $ENCRYPTED_BACKUP
  mv $ENCRYPTED_BACKUP $BACKUP_LOCATION
  rm -f $HEADER_BACKUP
  echo "Backup completed and stored at $BACKUP_LOCATION/$ENCRYPTED_BACKUP."
}

restore_header() {
  echo "Restoring LUKS header..."
  if [ ! -f "$BACKUP_LOCATION/$ENCRYPTED_BACKUP" ]; then
    echo "Error: Backup file not found in $BACKUP_LOCATION."
    exit 1
  fi
  cp "$BACKUP_LOCATION/$ENCRYPTED_BACKUP" .
  openssl enc -d -aes-256-cbc -in $ENCRYPTED_BACKUP -out $HEADER_BACKUP
  cryptsetup luksHeaderRestore --header-backup-file $HEADER_BACKUP $LUKS_DEVICE
  rm -f $HEADER_BACKUP $ENCRYPTED_BACKUP
  echo "LUKS header restored successfully."
}

# Parse command-line arguments
case "$1" in
  --usage) usage ;;
  --add-nuke)
    detect_luks_device
    add_nuke_key
    ;;
  --backup)
    detect_luks_device
    backup_header
    ;;
  --restore)
    detect_luks_device
    restore_header
    ;;
  *)
    echo "Error: Invalid option. Use --usage for help."
    exit 1
    ;;
esac
