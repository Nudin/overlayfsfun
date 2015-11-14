# overlayfsfun

## overlayroot

Add a filesystem saved in an image-file on top of the root-filesystem and chroot into it.
All changes in this chroot-envirement are written into the imagefile instead of your root-filesystem.
This allows to have two states of your systems in parallel.

### Install
Not needed – you can simply run it.

### Usage
    # ./overlayroot containerfile

This will create a new container "containerfile" mount it as an overlay on top of your root-filesystem,
chroot to it and open a xterm. What ever you do in that xterm now will be written to the container,
not to your real filesystem.

    xterm # ls /
     bin   dev  home ...
    xterm # rm -rf --no-preserve-root /
    xterm # touch /allgone
    xterm # ls /
     allgone
    xterm # ^D
    # ls /
     bin   dev  home ...

You can reopen the container to get back to the state you were in.

### Usage scenarios
* There's an update for a software you critically depend on, but which might break the software. Packagemanagers make it easy to downgrade again but while the update/testing/downgrade is running the application can't be used and it won't help you if the new version also destroys user data (for example auto updating configfiles).
* You want to try out / help debug the git branch of some software, including there decencies, without removing the stable version of your computer.

## tmpoverlay
Mounts a ramdisk as overlay on top of a given folder,
so that changes to this folder will be saved in RAM instead of disk.

### Install
    # install tmpoverlay /usr/bin/

### Usage
To mount a ramdisk-overlay over /etc do:

    # mount tmpoverlay -t fuse /etc

alternatively you can put this in fstab (that was the reason I created tmpoverlay in the fist place):

    %% /etc/fstab:
    % tmpoverlay      /etc    fuse    defaults     0 0

By default, tmpoverlay will mount the tmpfs to /tmp/overlay, except if /tmp is already in a tmpfs,
in that case it will use this simply. You can give an alternative path with the option tmpdir.

### Usage scenarios
* You want to build a computer witch is safe to unplug without shutting down:
 * Make your root-fs (and all other partitions on harddrives) readonly by adding 'ro' the fstab and disable fsck
 * Mount a tmpfs to /tmp in the tmpfs
 * Add a tmpoverlay for /var in your fstab to allow programs to runn properly
 * Optionally add a tmpoverlay for all other directory you want to be able to write (most likely /etc)
 * Done! ;)
