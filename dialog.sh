#!/usr/bin/bash

set -Eeuo pipefail
trap 'echo "Error line $LINENO. Error code: $?" >&2' ERR 

mapfile -t pkg < ./pkg
disks=()
lsblk_output=$(lsblk -o PATH,VENDOR -A -n -Q 'TYPE=="disk"')

while IFS= read -r line; do 
    read -ra disk <<< "$line"
    disks+=("${disk[0]}") # path
    disks+=("${disk[1]}") # vendor
done <<< $lsblk_output

disk=$(dialog --title "Disks" --menu "Select disk" 8 45 0 \
"${disks[@]}" \
2>&1 >/dev/tty)

dialog --title Warning --msgbox "${disk} disk will be formatted!" 0 0

sfdisk $disk << EOF
label: gpt
size=500M, type=U, bootable
size=4G, type=S
size=+, type=L
EOF

mkfs.fat -F32 "${disk}1" -n BOOT
mkswap "${disk}2" -L SWAP
mkfs.ext4 "${disk}3" -L ROOT

mount  "${disk}3" /mnt
mount --mkdir "${disk}1" /mnt/boot
swapon "${disk}2"

pacstrap -K /mnt "${pkg[@]}"

genfstab -L /mnt > /mnt/etc/fstab

arch-chroot /mnt \
ln -sf /mnt/usr/share/zoneinfo/Europe/Moscow /mnt/etc/localtime && \
hwclock --systohc && \
echo arch > /mnt/etc/hostname && \
passwd && \
bootctl install --esp-path=/mnt/boot && \
cp ./loader.conf /mnt/boot/loader/loader.conf && \
cp ./arch.conf /mnt/boot/loader/entries/arch.conf 

umount -R /mnt

dialog --title Reboot --msgbox "All done. Reboot now" 0 0

reboot