#!/usr/bin/bash

exit 0

username=$1

if [ $(id -u) = 0 ]; then
   echo "ERROR:"
   echo "this script must be run as non root"
   exit 1
fi

# from https://asdf-vm.com/guide/getting-started.html
arch-chroot /mnt /bin/su -c \
'git clone https://aur.archlinux.org/asdf-vm.git && cd asdf-vm && makepkg -si &&
echo 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"' >> ~/.bash_profile' $username

