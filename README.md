#RbuWSL: Rsync backup using Windows Subsystem for Linux
README is pending. More coming soon. 

## Motivation
I needed a faster method to quickly backup all my files on Windows to an external drive. Copying/pasting my users files took too long because non-modified files would be transferred also. With 500GB+ worth of data, this was not a feasible option. I found *rsync* as a solution. Rsync allows you to transfer files from source to destination quickly by only transferring new and modified files. RbuWSL seeks to allow Windows users to quickly backup their files to an external drive using *rsync*. 

## Description
RbuWSL's bashs script will backup your desired data on Windows 10 to an external drive using rsync. Rsync allows differential backup of data allowing only new/modified files to be transferred. On Windows 10, use of rsync can be achieved using Ubuntu (Bash) through Windows Subsystem for Linux (WSL). 


