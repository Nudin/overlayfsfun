# Installing overlayfs on Raspberry Pi

## Using pi3g-Kernel

    sudo apt-get install linux-source-3.18.10-lcd
    cd /usr/src/linux-source-3.18.10-lcd/
    sudo tar -xzf linux-source-3.18.10-lcd.tar.gz
    make menuconfig
    scripts/diffconfig
    make prepare
    sudo make SUBDIRS=fs/overlayfs/ modules_install
    sudo mkdir /lib/modules/3.18.10-v7+/extra/
    sudo mv /lib/modules/3.18.10-v7/extra/overlay.ko /lib/modules/3.18.10-v7+/extra/
    sudo rmdir /lib/modules/3.18.10-v7/extra/
    sudo rmdir /lib/modules/3.18.10-v7/
    sudo depmod
                                                    
## Using raspian-kernel

UNTESTED

    sudo apt-get install gcc-4.8 g++-4.8
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.6 20
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 50
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.6 20
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 50
    
    sudo wget https://raw.githubusercontent.com/notro/rpi-source/master/rpi-source -O /usr/bin/rpi-source
    sudo chmod +x /usr/bin/rpi-source
    /usr/bin/rpi-source -q --tag-update
    rpi-source
    cd linux
    
    make menuconfig
    scripts/diffconfig
    make prepare
    make SUBDIRS=fs/overlayfs/ modules
    sudo make SUBDIRS=fs/overlayfs/ modules_install
    sudo depmod
    
    
