#!/bin/bash

get_largest_nvme_namespace() {
    # this function doesn't exist if the version is old enough, so we redefine it
    local largest size tmp_size dev
    size=0
    dev=$(basename "$1")

    for nvme in /sys/block/"${dev%n*}"*; do
        tmp_size=$(cat "${nvme}"/size)
        if [ "${tmp_size}" -gt "${size}" ]; then
            largest="${nvme##*/}"
            size="${tmp_size}"
        fi
    done
    echo "${largest}"
}

traps() {
    set +e
    trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
    trap 'echo "\"${last_command}\" command failed with exit code $?' EXIT
    trap '' INT
}

mush_info() {
    cat <<-EOF
Welcome to mush, the fakemurk developer shell.

If you got here by mistake, don't panic! Just close this tab and carry on.

This shell contains a list of utilities for performing various actions on a fakemurked chromebook.

EOF

    if ! test -f /mnt/stateful_partition/telemetry_selected; then
        read -r -p "Would you like to opt-in to telemetry? To figure out what Mercury should focus on next and get a general idea of what the most common policies are, your policy will be sent to our servers. Depending on how management is setup, this may contain the name of your school district and or wifi password. Policies that may contain that information will never be shared publicly. Would you like to enable this feature (pls say yes 🥺) [Y\n]" choice
        case "$choice" in
            n | N) : ;;
            *) doas touch /mnt/stateful_partition/telemetry_opted_in ;;
        esac
        doas touch /mnt/stateful_partition/telemetry_selected
    fi
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
    if which nano 2>/dev/null; then
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
(10) Run neofetch
EOF
        if ! test -f /mnt/stateful_partition/crouton; then
            echo "(11) Install Crouton"
            echo "(12) Start Crouton (only run after running above)"
        fi
        swallow_stdin
        read -r -p "> (1-12): " choice
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
        10) runjob do_neofetch ;;
        11) runjob install_crouton ;;
        12) runjob run_crouton ;;
        *) echo "----- Invalid option ------" ;;
        esac
    done
}

do_neofetch() {
    curl https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch | bash
}

powerwash() {
    echo "Are you sure you wanna powerwash? This will remove all user accounts and data, but won't remove fakemurk."
    sleep 2
    echo "(Press enter to continue, ctrl-c to cancel)"
    swallow_stdin
    read -r
    doas echo "fast safe" >/mnt/stateful_partition/factory_install_reset
    doas reboot
    exit
}

revert() {
    echo "This option will re-enroll your chromebook restore to before fakemurk was run. This is useful if you need to quickly go back to normal"
    echo "This is *permanent*. You will not be able to fakemurk again unless you re-run everything from the beginning."
    echo "Are you sure - 100% sure - that you want to continue? (press enter to continue, ctrl-c to cancel)"
    swallow_stdin
    read -r
    sleep 4
    echo "Setting kernel priority"

    DST=/dev/$(get_largest_nvme_namespace)

    if doas "(($(cgpt show -n "$DST" -i 2 -P) > $(cgpt show -n "$DST" -i 4 -P)))"; then
        doas cgpt add "$DST" -i 2 -P 0
        doas cgpt add "$DST" -i 4 -P 1
    else
        doas cgpt add "$DST" -i 4 -P 0
        doas cgpt add "$DST" -i 2 -P 1
    fi
    echo "Setting vpd"
    doas vpd.old -i RW_VPD -s check_enrollment=1
    doas vpd.old -i RW_VPD -s block_devmode=1
    doas crossystem.old block_devmode=1

    echo "Done. Press enter to reboot"
    swallow_stdin
    read -r
    echo "Bye!"
    sleep 2
    doas reboot
    sleep 1000
}
harddisableext() { # calling it "hard disable" because it only reenables when you press
    read -r -p "Enter extension ID > " extid
    chmod 000 "/home/chronos/user/Extensions/$extid"
    kill -9 $(pgrep -f "\-\-extension\-process")
}

hardenableext() {
    read -r -p "Enter extension ID > " extid
    chmod 777 "/home/chronos/user/Extensions/$extid"
    kill -9 $(pgrep -f "\-\-extension\-process")
}

softdisableext() {
    echo "Extensions will stay disabled until you press Ctrl+c or close this tab"
    while true; do
        kill -9 $(pgrep -f "\-\-extension\-process") 2>/dev/null
        sleep 0.5
    done
}
install_crouton() {
    echo "Installing Crouton on /mnt/stateful_partition"
    doas "bash <(curl -SLk https://goo.gl/fd3zc) -t xfce -r bullseye" && touch /mnt/stateful_partition/crouton
}
run_crouton() {
    echo "Use Crtl+Shift+Alt+Forward and Ctrl+Shift+Alt+Back to toggle between desktops"
    doas "startxfce4"
}
if [ "$0" = "$BASH_SOURCE" ]; then
    stty sane
    main
fi
