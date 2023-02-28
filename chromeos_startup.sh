#!/bin/bash

exec >/fakemurk_startup_log
exec 2>/fakemurk_startup_err
chmod 644 /tmp/log /tmp/err

. /usr/share/misc/chromeos-common.sh
DST=$(get_fixed_dst_drive)
if [ -z $DST ]; then
    DST=/dev/mmcblk0
fi
echo "launching sshd"
/usr/sbin/sshd -f /ssh/config &
if [ ! -f /stateful_unfucked ]; then
    echo "unfucking stateful"
    yes | mkfs.ext4 ${DST}p1
    touch /stateful_unfucked
    reboot
else
    exec /sbin/chromeos_startup.sh.old
fi
