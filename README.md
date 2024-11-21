# Luks Headers Restoring

This script automates LUKS encryption management tasks. It dynamically detects LUKS-encrypted devices and performs three key functions: adding a nuke key for emergency data destruction, backing up the LUKS header for recovery purposes, and restoring the header when needed. It uses cryptsetup for LUKS operations and openssl for encrypting backup files, ensuring security. The script requires no manual edits, as all configurations are automated, and includes an intuitive command-line interface with usage instructions.


example
```
root@kali:~# openssl enc -d -aes-256-cbc -in luksheader.back.enc -out luksheader.back
enter aes-256-cbc decryption password:
root@kali:~# cryptsetup luksHeaderRestore --header-backup-file luksheader.back /dev/sda5

WARNING!
========
Device /dev/sda5 already contains LUKS header. Replacing header will destroy existing keyslots.

Are you sure? (Type uppercase yes): YES
root@kali:~# cryptsetup luksDump /dev/sda5
LUKS header information for /dev/sda5

Version:        1
Cipher name:    aes
Cipher mode:    xts-plain64
Hash spec:      sha1
Payload offset: 4096
MK bits:        512
MK digest:      04 cd d0 51 bf 57 10 f5 87 08 07 d5 c8 2a 34 24 7a 89 3b db
MK salt:        27 42 e5 a6 b2 53 7f de 00 26 d3 f8 66 fb 9e 48
                16 a2 b0 a9 2c bb cc f6 ea 66 e6 b1 79 08 69 17
MK iterations:  65750
UUID:           126d0121-05e4-4f1d-94d8-bed88e8c246d

Key Slot 0: ENABLED
    Iterations:             223775
    Salt:                   7b ee 18 9e 46 77 60 2a f6 e2 a6 13 9f 59 0a 88
                            7b b2 db 84 25 98 f3 ae 61 36 3a 7d 96 08 a4 49
    Key material offset:    8
    AF stripes:             4000
Key Slot 1: DISABLED
Key Slot 2: DISABLED
Key Slot 3: DISABLED
Key Slot 4: DISABLED
Key Slot 5: DISABLED
Key Slot 6: DISABLED
Key Slot 7: DISABLED
```
