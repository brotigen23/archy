# in Mb
ram_size(){
    local m=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    echo $(($m / 1024))
}
