#!/usr/bin/bash

set -Eeuo pipefail
trap 'echo "Error line $LINENO. Error code: $?" >&2' ERR 

mapfile -t pkg < ./pkg
disks=()
lsblk_output=$(lsblk -o PATH,VENDOR -A -n -Q 'TYPE=="disk"')

boot_size="500M"
#ram_size=$(free -g | grep 'Mem:' | awk '{print $2}')K
ram_size=$(grep MemTotal /proc/meminfo | awk '{print $2}')K
root_size="+"


while IFS= read -r line; do 
    read -ra disk <<< "$line"
    disks+=("${disk[0]}") # path
    disks+=("${disk[1]}") # vendor
done <<< $lsblk_output

disk=$(dialog --title "Disks" --menu "Select disk" 8 45 0 \
"${disks[@]}" \
2>&1 >/dev/tty)

# dialog --title Partition --msgbox \
# "${disk} disk will be formatted with next partitions: \ \n
# boot:${boot_size}\n \ 
# swap:${ram_size}\nroot:${root_size}" 0 0

sfdisk $disk << EOF
label: gpt
size="$boot_size", type=U, bootable
size=${ram_size}, type=S
size=$"root_size", type=L
EOF

mkfs.fat -F32 "${disk}1" -n BOOT
mkswap "${disk}2" -L SWAP
mkfs.ext4 "${disk}3" -L ROOT

mount  "${disk}3" /mnt
mount --mkdir "${disk}1" /mnt/boot
swapon "${disk}2"

pacstrap -K /mnt "${pkg[@]}"

genfstab -L /mnt > /mnt/etc/fstab

arch-chroot /mnt bash -c \
'ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime && \
hwclock --systohc && \
echo arch > /etc/hostname && \
passwd && \
bootctl install --esp-path=/boot && '

cp -r ./loader/ /mnt/boot/

umount -R /mnt

dialog --title Reboot --msgbox "All done. Reboot now" 0 0

reboot