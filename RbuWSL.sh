#!/bin/bash

############################################################################################
# Rsync backup using Windows Subsystem for Linux (RbuWSL)
############################################################################################
#
# Author: Zythyr https://github.com/zythyr 
# Last updated: 2018-01-13
# Version: 1.0 
#
# Description: 
# This bash script will backup your desired data on Windows 10 to an external drive 
# using rsync. Rsync allows differential backup of data. On Windows 10, this can be achieved
# using Ubuntu (Bash) through Windows Subsystem for Linux (WSL). 
#
# Requirements: 
# - Windows 10 v1709 or greater 
# - Ubuntu WSL: https://docs.microsoft.com/en-us/windows/wsl/install-win10 
# - Basic understanding of rsync 
#		https://linux.die.net/man/1/rsync
#		https://www.howtogeek.com/135533/how-to-use-rsync-to-backup-your-data-on-linux/ 
#		https://www.howtogeek.com/175008/the-non-beginners-guide-to-syncing-data-with-rsync/ 
#
# How to run:
# 0) Update the constants in this script and tailor for your backup needs  
# 1) Run Ubuntu (bash) on Windows 10
# 2) Navigate to location of this script 
# 3) Run the script by typing the command "./nameOfThisScript.sh"
#
# Suggestions for backup: 
# 1)Use the rsync option "--no-p --chmod=ugo=rwX" if you're paranoid about unaccessable files/folders due to ACL permissions 
#	Why: Because in the past, when rsync was used using Cygwin, there are permissions issues. https://superuser.com/a/1184342/607501   
#	This is not really needed but its a good safety measure. This script assumes that Ubuntu WSL can't affect ACL permissions on 
#	the destination backup drive, thus this option is NOT needed. 
# 2)If ACL permissions do get messed up and your files/folders are unaccessible then you can manually fix
#	using icacls.exe and takeown.exe 
#	https://technet.microsoft.com/en-us/library/cc753024(v=ws.11).aspx 
#	https://technet.microsoft.com/en-us/library/cc753525(v=ws.11).aspx 
#	https://stackoverflow.com/questions/2928738/how-to-grant-permission-to-users-for-a-directory-using-command-line-in-windows 
#	https://stackoverflow.com/a/31390693 
#
# Current issues:
# - Paranoid that this script will accidentally delete files on C drive and D drive become of the need for manual mounting/umount 
# - Sometimes mount/unmounting doesn't work properly 
# - Script yet not tested on network drives with SMB share and NFS shares. Will it cause permission issues??? Is it mountable? 
#
# Future work:
# - Improve this script syntax to follow POSIX standard: http://mywiki.wooledge.org/BashGuide http://s.ntnu.no/bashguide.pdf  
# - Make this script usable for network drives. Currently this script assumes a USB attached external drive  
#
# References and troubleshooting:
#		https://www.howtogeek.com/135533/how-to-use-rsync-to-backup-your-data-on-linux/ 
#		https://www.howtogeek.com/175008/the-non-beginners-guide-to-syncing-data-with-rsync/
#		Cacls: Displays and Modifies NTFS Access Control Lists https://technet.microsoft.com/en-us/library/cc976803.aspx
#		Icacls https://technet.microsoft.com/en-us/library/cc753525(v=ws.11).aspx  (newer to Cacls) 
#		How to Mount Removable Drives and Network Locations in the Windows Subsystem for Linux https://www.howtogeek.com/331053/how-to-mount-removable-drives-and-network-locations-in-the-windows-subsystem-for-linux/ 
#		Rsync and Cygwin based backup on Windows gives permission denied errors https://superuser.com/questions/1158846/rsync-and-cygwin-based-backup-on-windows-gives-permission-denied-errors 
#		WSL File System Support https://blogs.msdn.microsoft.com/wsl/2016/06/15/wsl-file-system-support/ 
#		POSIX permissions on DrvFs as per Services for UNIX https://github.com/Microsoft/WSL/issues/1799 
#		Leave ACL handling to Windows with Cygwin rsync https://superuser.com/questions/270894/leave-acl-handling-to-windows-with-cygwin-rsync  
#





#### CONSTANTS START

timeNOW=$(date +"%Y-%m-%d-%H-%M-%S") # Get current timestamp https://stackoverflow.com/questions/17066250/create-timestamp-variable-in-bash-script  

DESTINATION_DRIVE_LETTER="E" 										# This is the drive letter that shows up in Windows for your external hard drive that you want to backup to 
DESTINATION_MOUNT_NAME="temp_rbuwsl_rsync_backup"					# This is the name of the directory created under /mnt where the external drive will be mounted to 
DESTINATION_MOUNT_PATH=/mnt/"$DESTINATION_MOUNT_NAME"				# This is the mount path for the external drive 
DESTINATION_BACKUP_PATH="rbuwsl"									# This is the folder path in the external drive where you will be backup up to. Path is relative to root of the external drive.


SOURCE_WINDOWS_USERNAME="Username" 									# Username of the person on Windows where backup will be taken from 
SOURCE_BACKUP_PATH=""												# Path relative to the root of user personal folder where all the desired folders to be backed up are located


# List all the folders below that you want to backup. These folders should be located directly under the $SOURCE_BACKUP_PATH 
# https://stackoverflow.com/questions/8880603/loop-through-an-array-of-strings-in-bash 
declare -a SOURCE_BACKUP_PATH_FOLDERS=(
	"FolderA"
	"Folder B"
	"Folder C"
	)
	
#### CONSTANTS END 	



echo -e "\n=============== Welcome to RbuWSL: Rsync backup using Windows Subsystem for Linux  ===============\n"

read -p "What is the drive letter of the destination external drive? Default: $DESTINATION_DRIVE_LETTER " USER_INPUT_DESTINATION_DRIVE_LETTER
read -p "What is the folder path relative to root of external drive where you want to backup to (case sensitive)? Default: '$DESTINATION_BACKUP_PATH' " USER_INPUT_DESTINATION_BACKUP_PATH
read -p "What is the Windows username under which the files to be backed up are located (case sensitive)? Default: '$SOURCE_WINDOWS_USERNAME' " USER_INPUT_SOURCE_WINDOWS_USERNAME
read -p "What is the path relative to root of user's personal which contains all the folders you want to backup? (case sensitive)? Default: '$SOURCE_BACKUP_PATH' " USER_INPUT_SOURCE_BACKUP_PATH

if ! [[ -z "$USER_INPUT_DESTINATION_DRIVE_LETTER" ]]; then
	DESTINATION_DRIVE_LETTER="$USER_INPUT_DESTINATION_DRIVE_LETTER"
fi 

if ! [[ -z "$USER_INPUT_DESTINATION_BACKUP_PATH" ]]; then
	DESTINATION_BACKUP_PATH="$USER_INPUT_DESTINATION_BACKUP_PATH"
fi 

if ! [[ -z "$USER_INPUT_SOURCE_WINDOWS_USERNAME" ]]; then
	SOURCE_WINDOWS_USERNAME="$USER_INPUT_SOURCE_WINDOWS_USERNAME"
fi 

if ! [[ -z "$USER_INPUT_SOURCE_BACKUP_PATH" ]]; then
	SOURCE_BACKUP_PATH="$USER_INPUT_SOURCE_BACKUP_PATH"
fi 

SOURCE_PATH="/mnt/c/Users/$SOURCE_WINDOWS_USERNAME/$SOURCE_BACKUP_PATH"
DESTINATION_PATH="$DESTINATION_MOUNT_PATH/$DESTINATION_BACKUP_PATH"	

# Make sure to use --no-p --chmod=ugo=rwX on Windows https://superuser.com/a/1184342/607501 
## Although not needed, its better to be safe. That option was needed when using Cygwin, but this script is built for using rysnc on Windows with Ubuntu Bash (WSL)	
rsyncOptions="-avhP --no-p --chmod=ugo=rwX --stats --delete --log-file="$SOURCE_PATH/rsync-log-"$timeNOW".txt""s

	
#### SCRIPT STARTS HERE	


function mount_drive_drvfs
{
# Mount the external drive to desired Windows drive letter 
##	$1 = Drive letter to be mounted. When external drive is connected to PC, Windows automatically assigns a letter (ex: D, E, F...)
##	$2 = Mount path and directory name (ex: /mnt/temp_mount

# Create USB mount
##	https://blogs.msdn.microsoft.com/wsl/2017/04/18/file-system-improvements-to-the-windows-subsystem-for-linux/ 

if [ $1 = "C" ] || [ $1 = "c" ]; then 
	# SAFETY SO WE DON'T MESS UP THE WINDOWS C DRIVE
	echo -e "Mount: DANGER: Can't mount C drive. This drive already exist and is the root of Windows. Don't mess with this drive letter "
	exit
else 
	sudo mkdir $2
	echo -e "Mount: Directory $2 has been created"
	sudo mount -t drvfs $1: $2
	echo -e "Mount: External drive/USB at Windows drive letter $1 has been mounted to $2"
fi 
}	

function unmount_drive_drvfs
{
# Unmount the external drive from Ubuntu/Bash WSL. This won't unmount it from Windows File Explorer 
##	$1 = Drive letter to be unmounted. When external drive is connected to PC, Windows automatically assigns a letter (ex: D, E, F...)
##	$2 = Mount path and directory name (ex: /mnt/temp_mount

# Create USB mount
##	https://blogs.msdn.microsoft.com/wsl/2017/04/18/file-system-improvements-to-the-windows-subsystem-for-linux/ 

if [ $1 = "C" ] || [ $1 = "c" ]; then 
	# SAFETY SO WE DON'T MESS UP THE WINDOWS C DRIVE
	echo -e "Unmount: DANGER: Can't unmount C drive. This drive already exist and is the root of Windows. Don't mess with this drive letter "
	exit
else 
	sudo sudo umount $2
	echo -e "Unmount: Unmounting the mount at $2 which is the $1 drive" 
	echo -e "Unmount: Checking contents of $2 with ls command. See contents of $1 drive below:" 
	ls -la "$2"
	# For safety, we won't delete the mount directory with the commands below. 
	#echo -e "Unmount: Deleting $2 because we no longer need it"
	#sudo rm -rf $2
fi 
}	



echo -e "\n=============== BACKUP WITH RSYNC STARTING ==============="
echo -e "Destination drive letter: $DESTINATION_DRIVE_LETTER"
echo -e "Destination relative path: $DESTINATION_BACKUP_PATH"
echo -e "Source Windows username: $SOURCE_WINDOWS_USERNAME"
echo -e "Source relative path: $SOURCE_BACKUP_PATH"
echo -e "\n" 
echo -e "Rsync source path: $SOURCE_PATH"
echo -e "Rsync destination path: $DESTINATION_PATH"
echo -e "RSYNC OPTIONS: $rsyncOptions"

echo -e "\n"
	
# Give confirmation to start backing up 
# https://www.shellhacks.com/yes-no-bash-script-prompt-confirmation/ 
while true; do
    read -p "Do you wish to start mounting the drive and prepare for backup (Y/N)? " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done	

# Mount the destination drive 
mount_drive_drvfs $DESTINATION_DRIVE_LETTER $DESTINATION_MOUNT_PATH

echo -e "\n"
echo -e "Check to see if external drive is properly mounted. Folders in the root directory of the external drive will be listed below."
ls -la "$DESTINATION_MOUNT_PATH"
echo -e "\n"

# Give confirmation to start backing up 
# https://www.shellhacks.com/yes-no-bash-script-prompt-confirmation/ 
while true; do
    read -p "Is external drive properly mounted? Do you want to start backup? (Y/N/Q)? Y to continue, N to unmount and exit, Q to exit " yn
    case $yn in
        [Yy]* ) break;;
		[Nn]* ) unmount_drive_drvfs $DESTINATION_DRIVE_LETTER $DESTINATION_MOUNT_PATH; exit;;
        [Qq]* ) exit;;
        * ) echo "Please answer YES to continue, NO to unmount and exit, and Q to exit without unmounting";;
    esac
done


if ! [[ -d $DESTINATION_PATH ]]; then
	echo -e "\nDirectory $DESTINATION_BACKUP_PATH at destination does not exist. Creating it now. "
	mkdir -p "$DESTINATION_PATH"
	echo -e "Directory $DESTINATION_BACKUP_PATH at destination created."
fi

START_TIME=$(date +%s)

for i in "${SOURCE_BACKUP_PATH_FOLDERS[@]}"
do 
	echo -e "==========================================================================="
	echo -e "\nBacking up the folder: " "$SOURCE_PATH"/"$i" "\n"
	echo -e "==========================================================================="
	rsync $rsyncOptions "$SOURCE_PATH"/"$i" "$DESTINATION_PATH"
done 

END_TIME=$(date +%s)

echo -e "\nTime took to sync: $(( $END_TIME - $START_TIME)) seconds"


echo -e "\nRsync backup completed. Unmounting destination drive"

# Unmount the destination drive 
unmount_drive_drvfs $DESTINATION_DRIVE_LETTER $DESTINATION_MOUNT_PATH

echo -e "\n=============== BACKUP WITH RSYNC FINISHED ===============\n"
