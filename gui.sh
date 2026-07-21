#!/usr/bin/bash

# usage: 
# items=(1 "first option" 2 "second option")
# selected=$(choose_from_menu "title" "menu" items)
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
    echo "$choice"
}

msgbox(){
    local title="$1"
    local msg=$2

    dialog --title "$title" --msgbox \
    "$msg" 0 0
}
