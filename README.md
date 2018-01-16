# RbuWSL: Rsync backup using Windows Subsystem for Linux

README is pending. More coming soon. 

## Introduction
RbuWSL's script will backup your desired data on Windows 10 to an external drive using rsync. Rsync allows differential backup of data allowing only new/modified files to be transferred. On Windows 10, use of rsync can be achieved using Ubuntu (Bash) through Windows Subsystem for Linux (WSL). 

### Motivation
I needed a faster method to quickly backup all my files on Windows to an external drive. Copying/pasting my users files took too long because non-modified files would be transferred also. With 500GB+ worth of data, this was not a feasible option. I found *rsync* as a solution. Rsync allows you to transfer files from source to destination quickly by only transferring new and modified files. I created RbuWSL for my own personal use so I can quickly automate the backup process to an external drive using rsync. 

### Disclaimer
Use at your own risk. The author, maintainers, and contributors of this script are not responsible for any loss and corruption this script may cause to your files, system, and the drive you're backing up to. Make sure to read the README properly before using this script. 

### License

## Usage
### Requirements 
* Windows 10 (version 1709 Fall Creator Update or greater is preferred)
* Ubuntu/Bash WSL installed on Windows 10: https://docs.microsoft.com/en-us/windows/wsl/install-win10  
* Basic understanding of rsync and syncing options
    * How to Use rsync to Backup Your Data on Linux https://www.howtogeek.com/135533/how-to-use-rsync-to-backup-your-data-on-linux/ 
    * The Non-Beginner’s Guide to Syncing Data with Rsync https://www.howtogeek.com/175008/the-non-beginners-guide-to-syncing-data-with-rsync/ 
    * rsync(1) - Linux man page https://linux.die.net/man/1/rsync
* Basic understanding of Linux and command line commands for Bash Shell 
    * A Command Line Primer for Beginners https://lifehacker.com/5633909/who-needs-a-mouse-learn-to-use-the-command-line-for-almost-anything 
    * How Can I Quickly Learn Terminal Commands? https://lifehacker.com/how-can-i-quickly-learn-terminal-commands-1494082178
    * Learn Basic Linux Commands with This Downloadable Cheat Sheet https://lifehacker.com/learn-basic-linux-commands-with-this-downloadable-cheat-1552019180
### How to run
1. Edit the constants in this script and tailor for your backup needs. All constants can be found in the CONSTANTS section of the script. 
2. Run Ubuntu (bash) on Windows 10
3. Navigate to location of this script 
4. Run the script by typing the command: ./RbuWSL.sh
### Suggestions 
* Use the rsync option `-avhP --stats --delete` for basic use. 
	* These options will duplicate your source backup files onto the destination drive. The `--delete` option will be ensure to delete the files in the destination drive that no longer exist your source files. 
* Use the option `--no-p --chmod=ugo=rwX` to ensure no ACL permission issues occur. 
	* This is NOT really needed when using Ubuntu/Bash WSL on Windows. 
	* I use this option because I am paranoid of getting unaccessible files/folders due to ACL permission issues I had in the past when using rsync with Cygwin. Refer to https://superuser.com/a/1184342/607501 for more details.
* Modify the constants in this script so you do NOT have to type the settings every time you backup. 

### Example

## TODO
* Make this script universal so it's not just limited to using it with WSL 
* Improve this script syntax to follow POSIX standard: http://mywiki.wooledge.org/BashGuide http://s.ntnu.no/bashguide.pdf 
### Known Issues 
* This script has NOT been tested on Cygwin on Windows. Do NOT use with Cygwin. If you want to use it with Cygwin you will need to modify this script. 
* This script has NOT been tested on network drives (NFS/CIFS/SMB). 
	* Will need to test mounting/unmount network drives with Ubuntu/Bash WSL on Windows 10
	* Will need to test permissions and ensure no ACL permission issues occur 

## Personal references 
Links below are my personal references I read while writing this script. I am listing them in the README as my own personal bookmarks in case I need to refer to them in the future. 
###  Bash syntax 
* BashGuide http://mywiki.wooledge.org/BashGuide 
* BashGuide http://s.ntnu.no/bashguide.pdf
* The POSIX Shell And Utilities http://shellhaters.org/ 
* https://stackoverflow.com/questions/8880603/loop-through-an-array-of-strings-in-bash  
* https://www.shellhacks.com/yes-no-bash-script-prompt-confirmation/
### Mounting/Unmounting 
* WSL File System Support https://blogs.msdn.microsoft.com/wsl/2016/06/15/wsl-file-system-support/ 
* File System Improvements to the Windows Subsystem for Linux https://blogs.msdn.microsoft.com/wsl/2017/04/18/file-system-improvements-to-the-windows-subsystem-for-linux/ 
* How to Mount Removable Drives and Network Locations in the Windows Subsystem for Linux https://www.howtogeek.com/331053/how-to-mount-removable-drives-and-network-locations-in-the-windows-subsystem-for-linux/ 
### ACL Permissions Troubleshooting 
* https://superuser.com/a/1184342/607501 
* https://github.com/Microsoft/WSL/issues/1799
* using icacls.exe and takeown.exe 
	* https://technet.microsoft.com/en-us/library/cc753024(v=ws.11).aspx 
	* https://technet.microsoft.com/en-us/library/cc753525(v=ws.11).aspx 
	* https://stackoverflow.com/questions/2928738/how-to-grant-permission-to-users-for-a-directory-using-command-line-in-windows 
	* https://stackoverflow.com/a/31390693 
	* Cacls: Displays and Modifies NTFS Access Control Lists https://technet.microsoft.com/en-us/library/cc976803.aspx
	* Icacls https://technet.microsoft.com/en-us/library/cc753525(v=ws.11).aspx  (newer to Cacls) 
