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
(8) Emergency Revert & Re-Enroll
(9) Edit Pollen
EOF
        if ! test -f /mnt/stateful_partition/crouton; then
            echo "(10) Install Crouton"
        fi
        swallow_stdin
        read -r -p "> (1-11): " choice
        case "$choice" in
        1) runjob doas bash ;;
        2) runjob bash ;;
        3) runjob /usr/bin/crosh.old ;;
        4) runjob powerwash ;;
        5) runjob softdisableext ;;
        6) runjob harddisableext ;;
        7) runjob hardenableext ;;
        8) runjob revert ;;
        9) runjob edit /etc/opt/chrome/policies/managed/policy.json ;;
        10) runjob install_crouton ;;
        *) echo "invalid option" ;;
        esac
    done
}

powerwash() {
    echo "ARE YOU SURE YOU WANT TO POWERWASH??? THIS WILL REMOVE ALL USER ACCOUNTS"
    sleep 2
    echo "(press enter to continue, ctrl-c to cancel)"
    swallow_stdin
    read -r
    doas echo "fast safe" >/mnt/stateful_partition/factory_install_reset
    doas reboot
    exit
}

revert() {
    echo "This option will re-enroll your chromebook restore to before fakemurk was run. This is useful if you need to quickly go back to normal"
    echo "THIS IS A PERMANENT CHANGE!! YOU WILL NOT BE ABLE TO GO BACK UNLESS YOU UNENROLL AGAIN AND RUN THE SCRIPT, AND IF YOU UPDATE TO THE VERSION SH1MMER IS PATCHED, YOU MAY BE STUCK ENROLLED"
    echo "ARE YOU SURE YOU WANT TO CONTINUE? (press enter to continue, ctrl-c to cancel)"
    swallow_stdin
    read -r
    sleep 4
    echo "setting kernel priority"

    DST=/dev/$(get_largest_nvme_namespace)

    if (($(cgpt show -n "$DST" -i 2 -P) > $(cgpt show -n "$DST" -i 4 -P))); then
        cgpt add "$DST" -i 2 -P 0
        cgpt add "$DST" -i 4 -P 1
    else
        cgpt add "$DST" -i 4 -P 0
        cgpt add "$DST" -i 2 -P 1
    fi
    echo "setting vpd"
    vpd.old -i RW_VPD -s check_enrollment=1
    vpd.old -i RW_VPD -s block_devmode=1
    crossystem.old block_devmode=1

    echo "Done. Press enter to reboot"
    swallow_stdin
    read -r
    echo "bye!"
    sleep 2
    reboot
    sleep 1000
}
harddisableext() { # calling it "hard disable" because it only reenables when you press
    read -r -p "enter extension id>" extid
    chmod 000 "/home/chronos/user/Extensions/$extid"
    kill -9 $(pgrep -f "\-\-extension\-process")
}

hardenableext() {
    read -r -p "enter extension id>" extid
    chmod 777 "/home/chronos/user/Extensions/$extid"
    kill -9 $(pgrep -f "\-\-extension\-process")
}

softdisableext() {
    echo "Extensions will stay disabled until you press Ctrl+c or close this tab"
    while true; do
        kill -9 $(pgrep -f "\-\-extension\-process") 2>/dev/null
    done
}
install_crouton() {
    doas "bash <(curl -SLk https://goo.gl/fd3zc) -t xfce" && touch /mnt/stateful_partition/crouton
}
if [ "$0" = "$BASH_SOURCE" ]; then
    stty sane
    main
fi
