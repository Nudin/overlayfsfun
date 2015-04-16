# Overlayfs-HowTo

## Basic systax

To mount /upper on top of /lower into /merged do:

    $ mount mount -t overlay overlay -olowerdir=/lower,upperdir=/upper,workdir=/work /merged

The syntax for an equilivant fstab-entry is accordingly:

    overlay /merged overlay lowerdir=/lower,upperdir=/upper,workdir=/work 0 0

Since Kernel 4.0 you can use multible lower directories:

    mount -t overlay overlay -olowerdir=/lower1:/lower2:/lower3 /merged

## Limitations
    
You can choose arbitrary paths with the following limitations:

 * upperdir has to be on a supported filesystem
 * upperdir and workdir have to be on the same filesystem
 * workdir has to be empty
 * you can not mount on /

## Degeneration of paths

You can use the same directory for multiples of the four folders used in the first example,
except for the workdir with must always be a seperate empty file.

Quite usefull example – this mounts /upper on top of /lower and displays the result again in lower:

    $ mount mount -t overlay overlay -olowerdir=/lower,upperdir=/upper,workdir=/work /lower

Analogously:

    $ mount mount -t overlay overlay -olowerdir=/lower,upperdir=/upper,workdir=/work /upper

If you set upper and lower to the same path you get effectivly a bind-mount:

    $ mount mount -t overlay overlay -olowerdir=/lower,upperdir=/lower,workdir=/work /merged

And finaly you can set them all to the same directory, wich doesn't do anything at all:

    $ mount mount -t overlay overlay -olowerdir=/lower,upperdir=/lower,workdir=/work /lower

## Nesting

You can also nest the three dirs in funny but rarly usefull ways. Some examples:

    $ mount mount -t overlay overlay -olowerdir=/lower,upperdir=/lower/upper,workdir=/work /merged

This will show the content of /lower and /lower/upper in /merged and additionaly the content of /lower/upper in /merged/upper.


# More Information:
 * https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/Documentation/filesystems/overlayfs.txt
