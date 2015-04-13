#!/bin/bash

set -e # exit on error
#set -x # debug mode

pdir=/tmp
rootdir=${pdir}/newroot # Has to be an empty dir
cdir=${pdir}/overlay
upperdir=${cdir}/upperdir
workdir=${cdir}/work

umount_all() {
  if [[ "$rootdir" = ]] ; then
    echo "Error! Cant dismount!"; return
  fi
  cd /
  cleaned=0
  # unmount recursivly until all mounts in $rootdir are gone
  while [[ $cleaned -eq 0 ]]; do
    cleaned=1
	for i in $(cat /proc/mounts | awk '{print $2}' | grep "^$rootdir" | sort -r); do
       umount 2>/dev/null "${i/\\040/ }" && echo "umounted ${i/\\040/ } succesfully" || cleaned=0
    done
  done

  umount $cdir
}
trap umount_all EXIT

# The file for the container can be given in four different ways:
# * absolute path to file (exp: /home/bar/foo)
# * relative path (exp: data/foo)
# * pure filename (exp: foo) - IN THIS CASE IT WILL BE PUT IN THE URS-HOME-DIR
# * none - In this case we use ~/overlay
if [[ $# -eq 0 ]]; then
  cfile=${HOME}/overlay
else
  if [[ "${1:0:1}" == "/" ]]; then
    cfile=$1
  elif echo $1 | grep / ; then
    cfile=$(pwd)/$1
  else
    cfile=${HOME}/$1
  fi
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
  dd if=/dev/zero of=$cfile bs=4M count=250
  mkfs.ext4 -j $cfile
fi

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
           grep -v -e "^/run" -e "^/sys" -e "^/dev" -e "^/proc" -e "^/$" | \
           awk '{ print length, $0 }' | sort -n | cut -d" " -f2-); do
    for j in ${a[*]}; do
      if echo $i | grep "^$j" > /dev/null; then
        continue 2
      fi
    done
    echo mount --rbind $i .$i
    mount --rbind $i .$i
    a[${#a[*]}]=$i
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
