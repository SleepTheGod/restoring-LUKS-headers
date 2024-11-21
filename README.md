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
```
How to Nuke your Encrypted Kali Installation
There’s been a fair amount of discussion around the recently introduced LUKS nuke patch we added to the cryptsetup package in Kali Linux. We wanted to take this opportunity to better explain this feature, as well as demonstrate some useful approaches which are worthwhile getting to know.

LUKS Nuke in a Nutshell
As explained well By Michael Lee in his ZDNet article, when creating an encrypted LUKS container, a master key is generated at random. A passphrase is then used to encrypt the master key in turn. This process means that the passphrase is not directly coupled to the data. That is, if two sets of identical data are encrypted and the same passphrase used, the master keys remain unique to each set and cannot be swapped out. What this also means however, is that regardless of the passphrase used, if the master key is lost, recovering data is impossible. This process conveniently lends itself to being used as a nuke by deliberately wiping the keys.

Example Use Case of LUKS Nuke
Our main purpose for introducing this feature in Kali Linux is to simplify the process of securely traveling with confidential client information. While “LUKS Nuking” your drive will result in an inaccessible disk, it is possible to backup your keyslots beforehand and restore them after the fact. What this allows us to do is to “brick” our sensitive laptops before any travel, separate ourselves from the restoration keys (which we encrypt), and then “restore” them to the machines once back in a safe location. This way, if our hardware is lost or otherwise accessed midway through our travels, no one is able to restore the data on it, including ourselves.

There are other ways to delete your keyslots, however the advantage of the Nuke option is it is quick, easy, and does not require you to fully login to your Kali installation. If you maintain a backup of your header, you can Nuke the keyslots whenever you feel uncomfortable. Then conduct a restoration when you feel secure.

Try this for yourself
Let’s go through the motions of encrypting, backing up, destroying, and then restoring your data using Kali Linux. Start by downloading and installing Kali Linux 1.0.6 with Full Disk Encryption. Once that is done, you can verify your information as follows:

root@kali-crypto:~# cryptsetup luksDump /dev/sda5
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
As you can see, we have slot 0 enabled with slots 1 to 7 unused. At this point, we will add our nuke key:

root@kali-crypto:~# apt install cryptsetup-nuke-password
root@kali-crypto:~# dpkg-reconfigure cryptsetup-nuke-password
This didn’t change anything to the LUKS container, instead it installed the nuke password and a small hook in the initrd. This hook will detect when you enter your nuke password at boot time and it will call “cryptsetup luksErase” on your LUKS container at that time.

Wonderful. Now we need to back up the encryption keys. This can easily be done with the “luksHeaderBackup” option:

root@kali-crypto:~# cryptsetup luksHeaderBackup --header-backup-file luksheader.back /dev/sda5
root@kali-crypto:~# file luksheader.back
luksheader.back: LUKS encrypted file, ver 1 [aes, xts-plain64, sha1] UUID: 126d0121-05e4-4f1d-94d8-bed88e8c246d
root@kali-crypto:~#
So, in our case we would like to encrypt this data for storage. There are a number of ways this could be done, however we will use openssl to make the process quick and easy using default tools in Kali:

root@kali-crypto:~# openssl enc -aes-256-cbc -salt -in luksheader.back -out luksheader.back.enc
enter aes-256-cbc encryption password:
Verifying - enter aes-256-cbc encryption password:
root@kali-crypto:~# ls -lh luksheader.back*
-r-------- 1 root root 2.0M Jan  9 13:42 luksheader.back
-rw-r--r-- 1 root root 2.0M Jan  9 15:50 luksheader.back.enc
root@kali-crypto:~# file luksheader.back*
luksheader.back:     LUKS encrypted file, ver 1 [aes, xts-plain64, sha1] UUID: 126d0121-05e4-4f1d-94d8-bed88e8c246d
luksheader.back.enc: data
Great, now we have the encrypted header ready to be backed up. In this case, we would like to place the header somewhere that it is easily accessible. This could be as simple as on a USB thumb drive that is kept in a safe location. At this point, lets reboot and make use of the Nuke key and see how Kali responds.

So we used the Nuke key, and as expected we can no longer boot into Kali. Let’s see what happened on the actual disk by booting up into a Kali live CD and dumping the LUKS header again:

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

Key Slot 0: DISABLED
Key Slot 1: DISABLED
Key Slot 2: DISABLED
Key Slot 3: DISABLED
Key Slot 4: DISABLED
Key Slot 5: DISABLED
Key Slot 6: DISABLED
Key Slot 7: DISABLED
As we can see, no keyslots are in use. The Nuke worked as expected. To restore the header back in place, it’s a simple matter of retrieving the encrypted header from your USB drive. Once we have that, we can decrypt it and conduct our restore:

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
Our slots are now restored. All we have to do is simply reboot and provide our normal LUKS password and the system is back to its original state.
```
