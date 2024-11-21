#!/bin/bash

# Script to manage LUKS headers: backup, nuke, and restore.

DEVICE="/dev/sda5"
BACKUP_FILE="luksheader.back"
ENCRYPTED_BACKUP_FILE="luksheader.back.enc"
ENCRYPTION_PASSWORD="change_this_password" # Replace with a secure password or prompt user.

function usage() {
    echo "Usage: $0 {backup|nuke|restore}"
    echo "  backup   - Backup and encrypt LUKS header."
    echo "  nuke     - Nuke all keyslots on the LUKS device."
    echo "  restore  - Restore LUKS header from encrypted backup."
    exit 1
}

function backup_header() {
    echo "[+] Backing up LUKS header..."
    cryptsetup luksHeaderBackup --header-backup-file "$BACKUP_FILE" "$DEVICE" || {
        echo "[-] Failed to backup LUKS header."
        exit 1
    }
    echo "[+] Encrypting backup..."
    openssl enc -aes-256-cbc -salt -in "$BACKUP_FILE" -out "$ENCRYPTED_BACKUP_FILE" -k "$ENCRYPTION_PASSWORD" || {
        echo "[-] Failed to encrypt backup."
        exit 1
    }
    rm -f "$BACKUP_FILE"
    echo "[+] Backup and encryption complete: $ENCRYPTED_BACKUP_FILE"
}

function nuke_keyslots() {
    echo "[!] Nuking keyslots on the device..."
    cryptsetup luksErase "$DEVICE" || {
        echo "[-] Failed to nuke LUKS keyslots."
        exit 1
    }
    echo "[+] LUKS keyslots nuked successfully."
}

function restore_header() {
    echo "[+] Decrypting backup..."
    openssl enc -d -aes-256-cbc -in "$ENCRYPTED_BACKUP_FILE" -out "$BACKUP_FILE" -k "$ENCRYPTION_PASSWORD" || {
        echo "[-] Failed to decrypt backup."
        exit 1
    }
    echo "[!] Restoring LUKS header. WARNING: This will overwrite existing header!"
    cryptsetup luksHeaderRestore --header-backup-file "$BACKUP_FILE" "$DEVICE" || {
        echo "[-] Failed to restore LUKS header."
        exit 1
    }
    rm -f "$BACKUP_FILE"
    echo "[+] Header restored successfully. Reboot and use your original passphrase."
}

if [ $# -ne 1 ]; then
    usage
fi

case "$1" in
    backup)
        backup_header
        ;;
    nuke)
        nuke_keyslots
        ;;
    restore)
        restore_header
        ;;
    *)
        usage
        ;;
esac
