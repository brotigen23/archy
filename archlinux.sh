#!/usr/bin/bash

# https://wiki.archlinux.org/title/Installation_guide

# Variables

boot_size="500M"
swap_size=$(grep MemTotal /proc/meminfo | awk '{print $2}') # in KiB
swap_size=$(($swap_size / 1024))M # in MB
root_size="+"

disk=
disk_size=

# Functions

check_disk(){
    local disk=$1

    # проверка диска
    return 0
}

# usage:
# disks=()
# read_disds disks
read_disks(){   
    local -n d=$1 # use nameref for indirection

    while IFS= read -r line; do 
        read -ra disk <<< "$line"
        d+=("${disk[0]}") # path
        d+=("${disk[1]} (${disk[2]})") # vendor
    done <<< $(lsblk -o PATH,VENDOR,SIZE -A -n -Q 'TYPE=="disk"')

}

# usage: 
# create_partition /dev/sda 500M 500M +
create_partition(){
    # check if $1 exist
    # try run sfdisk --no-act
    sfdisk $disk << EOF
    label: gpt
    size="$boot_size", type=U, bootable
    size="$swap_size", type=S
    size="$root_size", type=L
EOF
}

make_fs(){
    local disk=$1

    mkfs.fat -F32 "${disk}1" -n BOOT
    mkswap "${disk}2" -L SWAP
    mkfs.ext4 "${disk}3" -L ROOT
}

mount_disk(){
    local disk=$1

    mount  "${disk}3" /mnt
    mount --mkdir "${disk}1" /mnt/boot
    swapon "${disk}2"
}

# usage:
# install_system "$(cat pkg.txt)" "Europe/Moscow"
install_system(){
    # TODO:
    # !check pkg string
    # !check timezone exists
    # !remove read ./pkg
    
    local packages=$1
    
    # new lines breaks $(cat pkg)
    #mapfile -t pkg < ./pkg
    #"${pkg[@]}"
    pacstrap -K /mnt $packages

    genfstab -L /mnt > /mnt/etc/fstab
}

set_timezone(){
    local timezone=$1
    arch-chroot /mnt bash -c \
    "ln -sf /usr/share/zoneinfo/$timezone /etc/localtime && \
    hwclock --systohc"
}

set_hostname(){
    arch-chroot /mnt bash -c "echo arch > /etc/hostname"
}

install_bootloader(){
    arch-chroot /mnt bash -c \
    "bootctl install --esp-path=/boot"
    cp -r ./conf/loader/ /mnt/boot/
}

# usage:
# post_create_user user 1432
root_passwd(){
    local pass=$1
    passwd --stdin <<< "$pass"
}

enable_system_servicies(){
    arch-chroot /mnt bash -c \
    "systemctl enable NetworkManager"
}

# usage:
# post_create_user user 1432
post_create_user(){
    local user=$1
    local pass=$2

    useradd -mG wheel "$user"
    passwd --stdin user <<< "$pass"
}

install_packages(){
    local packages=$1

    arch-chroot /mnt pacman -S "$packages"
}

