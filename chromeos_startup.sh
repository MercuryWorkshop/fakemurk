#!/bin/bash

. /usr/share/misc/chromeos-common.sh
DST=$(get_fixed_dst_drive)
if [ -z $DST ]; then
    DST=/dev/mmcblk0
fi

if [ ! -f /stateful_unfucked ]; then
    echo "unfucking stateful"
    yes | mkfs.ext4 ${DST}p1
    touch /stateful_unfucked
    reboot
else
    exec /sbin/chromeos_startup.old.sh
fi
