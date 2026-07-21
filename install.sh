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

create_partition

make_fs $disk

mount_disk $disk

install_system "$(cat ./conf/base.pkg | tr '\n' ' ')"

set_timezone "Europe/Moscow"

set_hostname

install_bootloader

root_passwd 1432

enable_system_servicies

post_create_user "user" "1432"
