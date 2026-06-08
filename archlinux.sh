#!/usr/bin/bash

# usage: `disks= ; read_disks disks`

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

read_disks(){   
    local -n d=$1 # use nameref for indirection

    while IFS= read -r line; do 
        read -ra disk <<< "$line"
        d+=("${disk[0]}") # path
        d+=("${disk[1]} (${disk[2]})") # vendor
    done <<< $(lsblk -o PATH,VENDOR,SIZE -A -n -Q 'TYPE=="disk"')

}

# usage: create_partition /dev/sda 500M 500M +
create_partition(){
    # check if $1 exist
    # try run sfdisk --no-act
    return 0
    local disk=$1

    local boot_size=$2
    local swap_size=$3
    local root_size=$4

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

install_system(){
    local packages=$1
    local timezone=$2

    mapfile -t pkg < ./pkg
    pacstrap -K /mnt "${pkg[@]}"

    genfstab -L /mnt > /mnt/etc/fstab

    arch-chroot /mnt bash -c \
    "ln -sf /usr/share/zoneinfo/$timezone /etc/localtime && \
    hwclock --systohc && \
    echo arch > /etc/hostname && \
    passwd && \
    bootctl install --esp-path=/boot && \
    systemctl enable NetworkManager"

    cp -r ./loader/ /mnt/boot/
}

install_packages(){
    local packages=$1

    arch-chroot /mnt pacman -S "$packages"
}
