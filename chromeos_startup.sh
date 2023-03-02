#!/bin/bash

exec >/fakemurk_startup_log
exec 2>/fakemurk_startup_err
chmod 644 /fakemurk_startup_log /fakemurk_startup_err

. /usr/share/misc/chromeos-common.sh
DST=/dev/$(get_largest_nvme_namespace)
if [ -z $DST ]; then
    DST=/dev/mmcblk0
fi

# we stage sshd and mkfs as a one time operation in startup instead of in the bootstrap script
# this is because ssh-keygen was introduced somewhere around R80, where many shims are still stuck on R73
# filesystem unfuck can only be done before stateful is mounted, which is perfectly fine in a shim but not if you run it while booted
# because mkfs is mean and refuses to let us format

# note that this will lead to confusing behaviour, since it will appear as if it crashed as a result of fakemurk

if [ ! -f /sshd_staged ]; then

    # thanks rory! <3
    echo "staging sshd"
    mkdir -p /ssh/root
    chmod -R 777 /ssh/root

    ssh-keygen -f /ssh/root/key -N '' -t rsa >/dev/null
    cp /ssh/root/key /rootkey
    chmod 600 /ssh/root

    cat >/ssh/config <<-EOF
AuthorizedKeysFile /ssh/%u/key.pub
StrictModes no
HostKey /ssh/root/key
Port 1337
EOF
    touch /sshd_staged
fi

echo "launching sshd"
/usr/sbin/sshd -f /ssh/config &

if [ -f /logkeys/active ]; then
    /usr/bin/logkeys -s -m /logkeys/keymap.map -o /mnt/stateful_partition/keylog
fi

if [ ! -f /stateful_unfucked ]; then
    echo "unfucking stateful"
    yes | mkfs.ext4 "${DST}p1"
    touch /stateful_unfucked
    reboot
else
    echo "-------------------- HANDING OVER TO REAL STARTUP --------------------"
    exec /sbin/chromeos_startup.sh.old
fi
