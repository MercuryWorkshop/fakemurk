#!/bin/bash

traps() {
    set +e
    trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
    trap 'echo "\"${last_command}\" command failed with exit code $?. THIS IS A BUG, REPORT IT HERE https://github.com/MercuryWorkshop/fakemurk"' EXIT
    trap '' INT
}

mush_info() {
    cat <<-EOF
Welcome to mush, the fakemurk developer shell.

If you got here by mistake, don't panic! Just close this tab and carry on.

This shell contains a list of utilities for performing certain actions on a fakemurked chromebook
EOF
}
doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

runjob() {
    trap 'kill -2 $! >/dev/null 2>&1' INT
    (
        $@
    )
    trap '' INT
}

swallow_stdin() {
    while read -t 0 notused; do
        read input
    done
}

edit() {
    if [ -f /usr/bin/nano ]; then
        doas nano "$@"
    else
        doas vi "$@"
    fi
}

main() {
    traps
    mush_info
    while true; do
        cat <<-EOF
(1) Root Shell
(2) Chronos Shell
(3) Crosh
(4) Powerwash
(5) Soft Disable Extensions
(6) Hard Disable Extensions
(7) Hard Enable Extensions
(8) Emergency Revert
(9) Edit Pollen
EOF
        swallow_stdin
        read -p "> (1-9): " choice
        case "$choice" in
        1) runjob doas bash ;;
        2) runjob bash ;;
        3) runjob /usr/bin/crosh.old ;;
        4) runjob powerwash ;;
        5) runjob softdisableext ;;
        6) runjob harddisableext "*" ;;
        7) runjob hardenableext "*" ;;
        8) runjob revert ;;
        9) runjob edit /etc/opt/chrome/policies/managed/policy.json ;;
        *) echo "invalid option" ;;
        esac
    done
}

powerwash() {
    swallow_stdin
    echo "ARE YOU SURE YOU WANT TO POWERWASH??? THIS WILL REMOVE ALL USER ACCOUNTS"
    sleep 2
    echo "(press enter to continue, ctrl-c to cancel)"
    doas echo "fast safe" >/mnt/stateful_partition/factory_install_reset
    doas reboot
    exit
}

revert() {
    :
}
editpollen() {
    :
}

harddisableext() { # calling it "hard disable" because it only reenables when you press
    if [ ! -d "/home/chronos/.extstore" ]; then
        mkdir /home/chronos/.extstore
    fi
    mv /home/chronos/user/Extensions/$1 /home/chronos/.extstore/
    chmod 000 /home/chronos/user/Extensions/$1

    doas restart ui
}

hardenableext() {
    chmod 777 /home/chronos/user/Extensions/$1
    mv /home/chronos/.extstore/$1 /home/chronos/user/Extensions/$1

    doas restart ui
}

softdisableext() {
    echo "Extensions will stay disabled until you press Ctrl+c or close this tab"
    while true; do
        kill -9 $(pgrep -f "\-\-extension\-process")
    done
}

if [ "$0" = "$BASH_SOURCE" ]; then
    stty sane
    main
fi
