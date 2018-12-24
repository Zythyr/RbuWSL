#!/bin/bash

############################################################################################
# Rsync backup using Windows Subsystem for Linux (RbuWSL)
############################################################################################
#
# Author: Zythyr https://github.com/zythyr
# Project: RbuWSL https://github.com/Zythyr/RbuWSL  
#
# Description: 
# RbuWSL's script will backup your desired data on Windows 10 to an external drive using rsync. 
# Rsync allows differential backup of data allowing only new/modified files to be transferred. 
# On Windows 10, use of rsync can be achieved using Ubuntu (Bash) through Windows Subsystem for Linux (WSL).
#
# Do NOT use this script without reading README
#
############################################################################################


########  CONSTANTS START  ########

DESTINATION_DRIVE_LETTER="E" 										# This is the drive letter that shows up in Windows for your external hard drive that you want to backup to 
DESTINATION_BACKUP_PATH="rbuwsl_backup"								# This is the folder path in the external drive where you will be backup up to. Path is relative to root of the external drive.

SOURCE_WINDOWS_USERNAME="Public" 									# Username of the person on Windows where backup will be taken from 
SOURCE_BACKUP_PATH=""												# Path relative to the root of user personal folder where all the desired folders to be backed up are located


# List all the folders below that you want to backup. These folders should be located directly under the $SOURCE_BACKUP_PATH 
# https://stackoverflow.com/questions/8880603/loop-through-an-array-of-strings-in-bash 
declare -a SOURCE_BACKUP_PATH_FOLDERS=(
	"Pictures"
	"My Music"
	"Documents"
	#"Downloads"
	)

# Make sure to use --no-p --chmod=ugo=rwX on Windows https://superuser.com/a/1184342/607501 
## Although not needed, its better to be safe. That option was needed when using Cygwin, but this script is built for using rysnc on Windows with Ubuntu Bash (WSL)	
#RSYNC_OPTIONS="-avhP --no-p --chmod=ugo=rwX --stats --delete"
RSYNC_OPTIONS="-avhP --stats --delete"


######## DO NOT TOUCH CONSTANTS BELOW ########
timeNOW=$(date +"%Y-%m-%d-%H-%M-%S") # Get current timestamp https://stackoverflow.com/questions/17066250/create-timestamp-variable-in-bash-script  
DESTINATION_MOUNT_NAME="temp_rbuwsl/backup_$timeNOW"					# This is the name of the directory created under /mnt where the external drive will be mounted to 
DESTINATION_MOUNT_PATH=/mnt/"$DESTINATION_MOUNT_NAME"				# This is the mount path for the external drive 

	
######## CONSTANTS END 	########



echo -e "\n=============== Welcome to RbuWSL: Rsync backup using Windows Subsystem for Linux  ===============\n"
echo -e "Lets setup the backup process. RbuWSL will ask you few questions regarding the backup.\n"
read -p "1. What is the drive letter of the destination external drive? Default: $DESTINATION_DRIVE_LETTER " USER_INPUT_DESTINATION_DRIVE_LETTER
read -p "2. What is the folder path relative to root of external drive where you want to backup to (case sensitive)? Default: '$DESTINATION_BACKUP_PATH' " USER_INPUT_DESTINATION_BACKUP_PATH
read -p "3. What is the Windows username under which the files to be backed up are located (case sensitive)? Default: '$SOURCE_WINDOWS_USERNAME' " USER_INPUT_SOURCE_WINDOWS_USERNAME
read -p "4. What is the path relative to root of user's personal which contains all the folders you want to backup? (case sensitive)? Default: '$SOURCE_BACKUP_PATH' " USER_INPUT_SOURCE_BACKUP_PATH
read -p "5. What options do you want to use for rsync? (case sensitive)? Default: $RSYNC_OPTIONS " USER_INPUT_RSYNC_OPTIONS

# Get user to update the SOURCE_BACKUP_PATH_FOLDERS which contains all the folders that need to be backed up in the source files. 
while true; do
    read -p "Did you edit this script and update the constant SOURCE_BACKUP_PATH_FOLDERS? If NOT, then type N to quit this script. You must edit the constant SOURCE_BACKUP_PATH_FOLDERS, to let RbuWSL know which folders you want to backup in your source directory. (Y/N)? " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done


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
if ! [[ -z "$USER_INPUT_RSYNC_OPTIONS" ]]; then
	RSYNC_OPTIONS="$USER_INPUT_RSYNC_OPTIONS"
fi

SOURCE_PATH="/mnt/c/Users/$SOURCE_WINDOWS_USERNAME/$SOURCE_BACKUP_PATH"
DESTINATION_PATH="$DESTINATION_MOUNT_PATH/$DESTINATION_BACKUP_PATH"	
RSYNC_LOG="--log-file="./rsync-log-"$timeNOW".txt""
	
#### SCRIPT STARTS HERE	


function mount_drive_drvfs
{
# Mount the external drive to desired Windows drive letter because in WSL external drive is not automatically mounted. 
##	$1 = Drive letter to be mounted. When external drive is connected to PC, Windows automatically assigns a letter (ex: D, E, F...)
##	$2 = Mount path and directory name (ex: /mnt/temp_mount

# Create USB mount
##	https://blogs.msdn.microsoft.com/wsl/2017/04/18/file-system-improvements-to-the-windows-subsystem-for-linux/ 

if [ $1 = "C" ] || [ $1 = "c" ]; then 
	# SAFETY SO WE DON'T MESS UP THE WINDOWS C DRIVE
	echo -e "Mount: DANGER: Can't mount C drive. This drive already exist and is the root of Windows. Don't mess with this drive letter "
	exit
else 
	sudo mkdir -p $2
	echo -e "Mount: Directory $2 has been created"
	userId=$(id -u) #Get the uid/gid of the user running the process 
	userGroup=$(id -g) #Get the uid/gid of the user running the process 
	sudo mount -t drvfs $1: $2 -o uid=$userId,gid=$userGroup #https://github.com/Microsoft/WSL/issues/3187#issuecomment-388904048
	echo -e "Mount: External drive/USB at Windows drive letter $1 has been mounted to $2"
fi 
}	

function unmount_drive_drvfs
{
# Unmount the external drive from Ubuntu/Bash WSL. This won't unmount it from Windows File Explorer. 
# Unmounting not necessary and if it fails no problem because oncew you remove the external drive, 
# the drive will be automatically unmounted from WSL
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
echo -e "RSYNC OPTIONS: $RSYNC_OPTIONS"

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

echo -e "\nRbuWSL will start backup in 5 seconds\n"
sleep 5


START_TIME=$(date +%s)

for i in "${SOURCE_BACKUP_PATH_FOLDERS[@]}"
do 
	echo -e "\n==========================================================================="
	echo -e "BACKING UP" 
	echo -e "Source: " "$SOURCE_PATH"/"$i"
	echo -e "Destination: " "$DESTINATION_PATH" 
	echo -e "==========================================================================="
	rsync $RSYNC_OPTIONS $RSYNC_LOG "$SOURCE_PATH"/"$i" "$DESTINATION_PATH"
done 

END_TIME=$(date +%s)

echo -e "\nTime took to sync: $(( $END_TIME - $START_TIME)) seconds"


echo -e "\nRsync backup completed. Unmounting destination drive"

# Unmount the destination drive 
unmount_drive_drvfs $DESTINATION_DRIVE_LETTER $DESTINATION_MOUNT_PATH

echo -e "\n=============== BACKUP WITH RSYNC FINISHED ===============\n"


# Introduction

# RbuWSL's script will backup your desired data on Windows 10 to an external drive using rsync. Rsync allows differential backup of data allowing only new/modified files to be transferred. On Windows 10, use of rsync can be achieved using Ubuntu (Bash) through Windows Subsystem for Linux (WSL).
# Motivation

# I needed a faster method to quickly backup all my files on Windows to an external drive. Copying/pasting my users files took too long because non-modified files would be transferred also. With 500GB+ worth of data, this was not a feasible option. I found rsync as a solution. Rsync allows you to transfer files from source to destination quickly by only transferring new and modified files. I created RbuWSL for my own personal use so I can quickly automate the backup process to an external drive using rsync.
# Disclaimer

# Use at your own risk. The author, maintainers, and contributors of this script are not responsible for any loss and corruption this script may cause to your files, system, and the drive you are backing up to. Make sure to read the README properly before using this script.
# License

# Coming soon
# Usage
# How to run

    # Edit the constants in this script and tailor for your backup needs. All constants can be found in the CONSTANTS section of the script.
    # Run Ubuntu (bash) on Windows 10. (Win+R) Run >> ubuntu.exe
    # Navigate to location of this script. Example: cd /mnt/c/Users/Username/Downloads/RbuWSL
    # Run the script by typing the command: ./RbuWSL.sh

# Requirements

    # Windows 10 (version 1709 Fall Creator Update or greater is preferred)
    # Ubuntu/Bash WSL installed on Windows 10: https://docs.microsoft.com/en-us/windows/wsl/install-win10
    # Basic understanding of rsync and syncing options
        # How to Use rsync to Backup Your Data on Linux https://www.howtogeek.com/135533/how-to-use-rsync-to-backup-your-data-on-linux/
        # The Non-Beginner’s Guide to Syncing Data with Rsync https://www.howtogeek.com/175008/the-non-beginners-guide-to-syncing-data-with-rsync/
        # rsync(1) - Linux man page https://linux.die.net/man/1/rsync
    # Basic understanding of Linux and command line commands for Bash Shell
        # A Command Line Primer for Beginners https://lifehacker.com/5633909/who-needs-a-mouse-learn-to-use-the-command-line-for-almost-anything
        # How Can I Quickly Learn Terminal Commands? https://lifehacker.com/how-can-i-quickly-learn-terminal-commands-1494082178
        # Learn Basic Linux Commands with This Downloadable Cheat Sheet https://lifehacker.com/learn-basic-linux-commands-with-this-downloadable-cheat-1552019180

# Suggestions

    # Modify the constants in this script so you do NOT have to type the settings every time you backup.
    # Use the rsync option -avhP --stats --delete for basic use.
        # These options will duplicate your source backup files onto the destination drive. The --delete option will be ensure to delete the files in the destination drive that no longer exist your source files.
    # Use the option --no-p --chmod=ugo=rwX to ensure no ACL permission issues occur.
        # This is NOT really needed when using Ubuntu/Bash WSL on Windows.
        # I use this option because I am paranoid of getting unaccessible files/folders due to ACL permission issues I had in the past when using rsync with Cygwin. Refer to https://superuser.com/a/1184342/607501 for more details.

# Example

# Assume your name is John and when you connect your external drive to Windows PC, it shows up as drive G, and you want to backup the following folders: Pictures, My Music, and Downloads to the JohnBackup folder in the root of your external drive. Then you would modify the CONSTANTS in the RbuWSL.sh file to as shown below.

# DESTINATION_DRIVE_LETTER="G" DESTINATION_BACKUP_PATH="JohnBackup" SOURCE_WINDOWS_USERNAME="John" SOURCE_BACKUP_PATH="" declare -a SOURCE_BACKUP_PATH_FOLDERS=( "Pictures" "My Music" "Downloads" )

# TODO

    # Make this script universal so it's not just limited to using it with WSL
    # Improve this script syntax to follow POSIX standard: http://mywiki.wooledge.org/BashGuide http://s.ntnu.no/bashguide.pdf

# Known Issues

    # This script has NOT been tested on Cygwin on Windows. Do NOT use with Cygwin. If you want to use it with Cygwin you will need to modify this script.
    # This script has NOT been tested on network drives (NFS/CIFS/SMB).
        # Will need to test mounting/unmount network drives with Ubuntu/Bash WSL on Windows 10
        # Will need to test permissions and ensure no ACL permission issues occur

# Personal references

# Links below are my personal references I read while writing this script. I am listing them in the README as my own personal bookmarks in case I need to refer to them in the future.
# Bash syntax

    # BashGuide http://mywiki.wooledge.org/BashGuide
    # BashGuide http://s.ntnu.no/bashguide.pdf
    # The POSIX Shell And Utilities http://shellhaters.org/
    # https://stackoverflow.com/questions/8880603/loop-through-an-array-of-strings-in-bash
    # https://www.shellhacks.com/yes-no-bash-script-prompt-confirmation/

# Mounting/Unmounting

    # WSL File System Support https://blogs.msdn.microsoft.com/wsl/2016/06/15/wsl-file-system-support/
    # File System Improvements to the Windows Subsystem for Linux https://blogs.msdn.microsoft.com/wsl/2017/04/18/file-system-improvements-to-the-windows-subsystem-for-linux/
    # How to Mount Removable Drives and Network Locations in the Windows Subsystem for Linux https://www.howtogeek.com/331053/how-to-mount-removable-drives-and-network-locations-in-the-windows-subsystem-for-linux/

# ACL Permissions Troubleshooting

    # https://superuser.com/a/1184342/607501
    # https://github.com/Microsoft/WSL/issues/1799
    # using icacls.exe and takeown.exe
        # https://technet.microsoft.com/en-us/library/cc753024(v=ws.11).aspx
        # https://technet.microsoft.com/en-us/library/cc753525(v=ws.11).aspx
        # https://stackoverflow.com/questions/2928738/how-to-grant-permission-to-users-for-a-directory-using-command-line-in-windows
        # https://stackoverflow.com/a/31390693
        # Cacls: Displays and Modifies NTFS Access Control Lists https://technet.microsoft.com/en-us/library/cc976803.aspx
        # Icacls https://technet.microsoft.com/en-us/library/cc753525(v=ws.11).aspx (newer to Cacls)

