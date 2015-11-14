#!/bin/bash

set -e      # exit on error
#set -x     # debug mode

pdir=/tmp                    # working directory
rootdir=${pdir}/newroot      # mountpint of the new root
cdir=${pdir}/overlay         # mountpint of the container
csize=256M                   # size of container
upperdir=${cdir}/upperdir    # 
workdir=${cdir}/work         # the upper- and workdir are in the containerfile 


err() {
   echo $*
   exit
}

# Undo all mount made by this script
umount_all() {
   if [[ "$rootdir" = "" ]] ; then
      echo "Error: Can't dismount."; return
   fi
   cd /
   cleaned=0
   echo -n "Releasing mounts within container: " 
   # unmount recursively until all mounts in $rootdir are gone
   while [[ $cleaned -eq 0 ]]; do
      cleaned=1
      for i in $(cat /proc/mounts | awk '{print $2}' | grep "^$rootdir" | sort -r); do
         umount 2>/dev/null "${i/\\040/ }" && echo "umounted ${i/\\040/ } succesfully" || cleaned=0
      done
   done
      echo " done."

   umount $cdir 2>/dev/null || :
}

if [ $EUID -ne 0 ]; then
      err "Error: This script must be run as root."
fi

# make sure $rootdir is an empty dir
test -d $rootdir || mkdir -p $rootdir
! test -e $rootdir/*

# The file for the container can be given in four different ways:
# * absolute path to file (exp: /home/bar/foo)
# * relative path (exp: data/foo)
# * -n and pure filename (exp: -n foo) - in this case it will be put in the urs-home-dir
# * none - In this case we use ~/overlay
if [[ $# -eq 0 ]]; then
   cfile=${HOME}/overlay
elif [[ $# -eq 1 ]]; then
   cfile=$(readlink -m $1)
elif [[ $# -eq 2 ]]; then
   if [[ "$1" = "-n" ]]; then
      cfile=${HOME}/$(basename $2)
   else
      err "Wrong usage"
   fi
else
   err "Wrong usage"
fi

# Test if kernel uses grsecurity with chroot_deny_unix
# if this is the case disable it, otherwise sokets won't work
# this would prevent you from running graphical programs
if [[ $(sysctl kernel.grsecurity.chroot_deny_unix 2>/dev/null | tail -c2) -eq 1 ]] ; then
   sysctl kernel.grsecurity.chroot_deny_unix=0
fi

# Mount kernelmodule of overlayfs
modprobe overlay

# Check if containerfile exist
# create otherwise
echo $cfile 
if [[ ! -f $cfile ]]; then
   truncate -s $csize $cfile
   mkfs.ext4 -qF $cfile
fi

# if anything fails make sure all mounts are cleaned up
trap umount_all EXIT

# Mount containerfile to containerdir
mkdir -p $cdir
mount $cfile $cdir

# Mount overlay
mkdir -p $rootdir
mkdir -p $upperdir
mkdir -p $workdir
mount -t overlay overlay -olowerdir=/,upperdir=$upperdir,workdir=$workdir $rootdir

# Mount systemfolders
cd $rootdir
mount -t proc proc proc/
mount --rbind /sys sys/
mount --rbind /dev dev/
mount --rbind /run run/

# Mount all additional partitions
a=()
for i in $(cat /proc/mounts | awk '{print $2}' | grep "^/" | \
           egrep -v '^/(run|sys|dev|proc|$)' |\
           awk '{ print length, $0 }' | sort -n | cut -d" " -f2-); do
   for j in ${a[*]}; do
      if echo "$i" | grep -q "^$j"; then
         continue 2
      fi
   done
   echo mount --rbind "$i" ".$i"
   mount --rbind "$i" ".$i"
   a[${#a[*]}]="$i"
done

# Allow connection to X-Server from within chroot
xhost +local: || :

# Put bindmounts in slave mode
for i in $(cat /proc/mounts | awk '{print $2}' | grep $rootdir); do
   mount --make-slave "${i/\\040/ }"
done

# Start chroot
chroot . xterm -e "echo -e '\e[1mWelcome to the Overlay-system! \e[0m \n\nAll changes made here will be written in the Imagefile. You will be back in the real-system when you exit this shell.'; export DISPLAY=${DISPLAY}; cd; bash"

# unmount everything
umount_all
