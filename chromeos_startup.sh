#!/bin/bash

exec >/fakemurk_startup_log
exec 2>/fakemurk_startup_err
chmod 644 /fakemurk_startup_log /fakemurk_startup_err

. /usr/share/misc/chromeos-common.sh
DST=$(get_fixed_dst_drive)
if [ -z $DST ]; then
    DST=/dev/mmcblk0
fi
if [ ! -f /sshd_staged ]; then

    echo "staging sshd"
    # thanks rory! <3
    mkdir -p $ROOT/ssh/root
    chmod -R 777 $ROOT/ssh/root

    ssh-keygen -f $ROOT/ssh/root/key -N '' -t rsa >/dev/null
    cp $ROOT/ssh/root $ROOT/rootkey
    chmod 600 $ROOT/ssh/root
    chmod 644 $ROOT/rootkey

    cat >$ROOT/ssh/config <<-EOF
AuthorizedKeysFile /ssh/%u/key.pub
StrictModes no
HostKey /ssh/root/key
Port 1337
EOF
    touch /sshd_staged
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
