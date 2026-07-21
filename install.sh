#!/usr/bin/bash

set -Eeuo pipefail
trap 'echo "Error line $LINENO. Error code: $?" >&2' ERR 

. ./archlinux.sh

. ./gui.sh

disks=()
read_disks disks

disk=$(choose_from_menu "Select disk" "" disks)

msgbox \
'the disk will be marked up as follows' \
"\n|-- $disk\n\
|   |----- boot("$boot_size")\n\
|   |----- swap("$swap_size")\n\
|   |----- root(remaining)\n"

create_partition $disk $boot_size $swap_size $root_size

make_fs $disk

mount_disk $disk

install_system $(cat ./conf/base.pkg) "Europe/Moscow"

exit 0

lsblk_output=$(lsblk -o PATH,VENDOR,SIZE -A -n -Q 'TYPE=="disk"')
disks=()
while IFS= read -r line; do 
    read -ra disk <<< "$line"
    disks+=("${disk[0]}") # path
    disks+=("${disk[1]} ${disk[2]}") # vendor and size
done <<< $lsblk_output

disk=$(dialog --title "Disks" --menu "Select disk" 8 45 0 \
"${disks[@]}" \
2>&1 >/dev/tty)

boot_size="500M"
swap_size=$(grep MemTotal /proc/meminfo | awk '{print $2}')K
root_size="+"

dialog --title Partition --msgbox \
"${disk} disk will be formatted with next partitions:\n \
boot:${boot_size}\n \
swap:${swap_size}\n \
root:${root_size}" \ 
0 0


sfdisk $disk << EOF
label: gpt
size="$boot_size", type=U, bootable
size="$swap_size", type=S
size="$root_size", type=L
EOF

mkfs.fat -F32 "${disk}1" -n BOOT
mkswap "${disk}2" -L SWAP
mkfs.ext4 "${disk}3" -L ROOT

mount  "${disk}3" /mnt
mount --mkdir "${disk}1" /mnt/boot
swapon "${disk}2"

mapfile -t pkg < ./pkg
pacstrap -K /mnt "${pkg[@]}"

genfstab -L /mnt > /mnt/etc/fstab

arch-chroot /mnt bash -c \
'ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime && \
hwclock --systohc && \
echo arch > /etc/hostname && \
passwd && \
bootctl install --esp-path=/boot && \
systemctl enable NetworkManager'

cp -r ./loader/ /mnt/boot/

umount -R /mnt
swapoff /dev/sda2

dialog --title Reboot --msgbox "All done. Reboot now" 0 0

reboot