disk_paths=()
disk_vendors=()
disks=()
lsblk_output=$(lsblk -o PATH,VENDOR -A -n -Q 'TYPE=="disk"')

while IFS= read -r line; do 
    read -ra disk <<< "$line"
    disk_paths+=(${disk[0]})
    disk_vendors+=(${disk[1]})
    disks+=(${disk[@]})
done <<< $lsblk_output

echo "${disk_paths[@]}"
echo "${disk_vendors[@]}"
# exit 0


disk=$(dialog --title "Disks" --menu "Select disk" 8 45 0 \
"${disks[@]}" \
2>&1 >/dev/tty)

echo $disk

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
mount -mkdir "${disk}1" /mnt/boot
swapon "${disk}2"

pacstrap -K /mnt "${packages}"

genfstab -L /mnt > /mnt/etc/fstab

arch-chroot /mnt \
"ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime && \
hwclock --systohc && \
echo arch > /etc/hostname && \
passwd && \
bootctl install --esp-path=/mnt/boot&& \
echo ```
default  arch.conf
timeout  1
console-mode max
editor   no
``` > /boot/loader/loader.conf && \
echo ```
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root="LABEL=ROOT" rw
``` > /boot/loader/entries/arch.conf "

umount -R /mnt

#dialog --title Reboot --msgbox "All done. Reboot now" 0 0

#reboot