#!/usr/bin/bash

. ./archlinux.sh

# usage: items=(); selected=$(choose_from_menu "title" "menu" items)
choose_from_menu(){
    local title=$1
    local msg=$2
    local -n i=$3
    choice=$(dialog \
    --title "$title" \
    --menu "$msg" \
    8 45 0 \
    "${i[@]}" \
    2>&1 >/dev/tty )
    printf '%s' "$choice"
}

msgbox(){
    local title="$1"
    local msg=$2

    dialog --title "$title" --msgbox \
    "$msg" 0 0
}

# boot_size="500M"
# swap_size=$(grep MemTotal /proc/meminfo | awk '{print $2}')
# swap_size=$(($swap_size / 1024 / 1024 + 1))
# root_size="+"
# disk="/dev/sdd"
# disk_size=$(($(sudo fdisk -s ${disk}) / 1024 / 1024))

# echo $disk_size
# exit

# msgbox \
# 'the disk will be marked up as follows' \
# "\n|-- $disk\n\
# |   |----- boot("$boot_size")\n\
# |   |----- swap("$(numfmt --to=iec-i --suffix=B --format="%.2f" <<< $swap_size)")\n\
# |   |----- root(remaining)\n"
