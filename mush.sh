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
    trap 'echo "\"${last_command}\" command failed with exit code $?. THIS IS A BUG, REPORT IT HERE https://github.com/MercuryWorkshop/fakemurk"' EXIT
    trap '' INT
}

mush_info() {
    cat <<-EOF
Welcome to mush, the fakemurk developer shell.

If you got here by mistake, don't panic! Just close this tab and carry on.

This shell contains a list of utilities for performing certain actions on a fakemurked chromebook

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
EOF
        if ! test -d /mnt/stateful_partition/crouton; then
            echo "(10) Install Crouton"
        else
            echo "(11) Start Crouton"
        fi
        echo "(12) Attempt to update to the latest chrome os version (BETA, BUGGY, MAY BREAK)"
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
        10) runjob install_crouton ;;
        11) runjob start_crouton ;;
        12) runjob attempt_update ;;
        *) echo "invalid option" ;;
        esac
    done
}
# https://chromium.googlesource.com/chromiumos/docs/+/master/lsb-release.md
lsbval() {
  local key="$1"
  local lsbfile="${2:-/etc/lsb-release}"

  if ! echo "${key}" | grep -Eq '^[a-zA-Z0-9_]+$'; then
    return 1
  fi

  sed -E -n -e \
    "/^[[:space:]]*${key}[[:space:]]*=/{
      s:^[^=]+=[[:space:]]*::
      s:[[:space:]]+$::
      p
    }" "${lsbfile}"
}
get_booted_kernnum() {
    if doas "((\$(cgpt show -n \"$dst\" -i 2 -P) > \$(cgpt show -n \"$dst\" -i 4 -P)))"; then
        echo -n 2
    else
        echo -n 4
    fi
}
opposite_num() {
    if [ "$1" == "2" ]; then
        echo -n 4
    elif [ "$1" == "4" ]; then
        echo -n 2
    elif [ "$1" == "3" ]; then
        echo -n 5
    elif [ "$1" == "5" ]; then
        echo -n 3
    else
        return 1
    fi
}
attempt_update(){
    local builds=$(curl https://chromiumdash.appspot.com/cros/fetch_serving_builds?deviceCategory=Chrome%20OS)
    local release_board=$(lsbval CHROMEOS_RELEASE_BOARD)
    local board=${release_board%%-*}
    local hwid=$(jq "(.builds.$board[] | keys)[0]" <<<"$builds")
    local hwid=${hwid:1:-1}
    local latest_milestone=$(jq "(.builds.$board[].$hwid.pushRecoveries | keys) | .[length - 1]" <<<"$builds")
    local remote_version=$(jq ".builds.$board[].$hwid[$latest_milestone].version" <<<"$builds")
    local remote_version=${remote_version:1:-1}
    local local_version=$(lsbval GOOGLE_RELEASE)

    if (( ${remote_version%%\.*} > ${local_version%%\.*} )); then
        echo "updating to ${remote_version}. THIS WILL DELETE YOUR REVERT BACKUP AND YOU WILL NO LONGER BE ABLE TO REVERT! THIS MAY ALSO DELETE ALL USER DATA!! press enter to confirm, ctrl-c to cancel"
        read -r
        sleep 4
        # read choice
        local reco_dl=$(jq ".builds.$board[].$hwid.pushRecoveries[$latest_milestone]" <<< "$builds")
        local tmpdir=/mnt/stateful_partition/update_tmp/
        doas mkdir $tmpdir
        echo "downloading ${remote_version} from ${reco_dl}"
        curl "${reco_dl:1:-1}" | doas "dd of=$tmpdir/image.zip status=progress"
        echo "unzipping update binary"
        cat $tmpdir/image.zip | gunzip | doas "dd of=$tmpdir/image.bin status=progress"
        doas rm -f $tmpdir/image.zip
        echo "invoking image patcher"
        doas image_patcher.sh "$tmpdir/image.bin"

        local loop=$(doas losetup -f | tr -d '\r')
        doas losetup -P "$loop" "$tmpdir/image.bin"
        echo "performing update"
        local dst=/dev/$(get_largest_nvme_namespace)
        local tgt_kern=$(opposite_num $(get_booted_kernnum))
        local tgt_root=$(( $tgt_kern + 1 ))

        local kerndev=${dst}p${tgt_kern}
        local rootdev=${dst}p${tgt_root}
        echo "installing kernel patch to ${kerndev}"
        doas dd if="${loop}p4" of="$kerndev" status=progress
        echo "installing root patch to ${rootdev}"
        doas dd if="${loop}p3" of="$rootdev" status=progress
        echo "setting kernel priority"
        doas cgpt add "$dst" -i 4 -P 0
        doas cgpt add "$dst" -i 2 -P 0
        doas cgpt add "$dst" -i "$tgt_kern" -P 1

        doas crossystem.old block_devmode=0
        doas vpd -i RW_VPD -s block_devmode=0

        # doas rm -rf $tmpdir
    
    else
        echo "update not required"
    fi
}
powerwash() {
    echo "ARE YOU SURE YOU WANT TO POWERWASH??? THIS WILL REMOVE ALL USER ACCOUNTS"
    sleep 2
    echo "(press enter to continue, ctrl-c to cancel)"
    swallow_stdin
    read -r
    doas rm -f /stateful_unfucked
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

    if doas "((\$(cgpt show -n \"$DST\" -i 2 -P) > \$(cgpt show -n \"$DST\" -i 4 -P)))"; then
        doas cgpt add "$DST" -i 2 -P 0
        doas cgpt add "$DST" -i 4 -P 1
    else
        doas cgpt add "$DST" -i 4 -P 0
        doas cgpt add "$DST" -i 2 -P 1
    fi
    echo "setting vpd"
    doas vpd -i RW_VPD -s check_enrollment=1
    doas vpd -i RW_VPD -s block_devmode=1
    doas crossystem.old block_devmode=1
    
    rm -f /stateful_unfucked

    echo "Done. Press enter to reboot"
    swallow_stdin
    read -r
    echo "bye!"
    sleep 2
    doas reboot
    sleep 1000
}
harddisableext() { # calling it "hard disable" because it only reenables when you press
    echo "Please choose the extension you wish to disable."
    echo "(1) GoGuardian"
    echo "(2) Securly Filter"
    echo "(3) LightSpeed Filter"
    echo "(4) Cisco Umbrella"
    echo "(5) ContentKeeper Authenticator"
    echo "(6) Hapara"
    echo "(7) iboss"
    echo "(8) LightSpeed Classroom"
    echo "(9) Blocksi"
    echo "(10) Linewize"
    echo "(11) Securly Classroom"
    echo "(12) Impero"
    echo "(13) put extension ID in manually"
    read -r -p "> (1-13): " choice
    case "$choice" in
    1) extid=haldlgldplgnggkjaafhelgiaglafanh;;
    2) extid=iheobagjkfklnlikgihanlhcddjoihkg;;
    3) extid=adkcpkpghahmbopkjchobieckeoaoeem;;
    4) extid=jcdhmojfecjfmbdpchihbeilohgnbdci;;
    5) extid=jdogphakondfdmcanpapfahkdomaicfa;;
    6) extid=aceopacgaepdcelohobicpffbbejnfac;;
    7) extid=kmffehbidlalibfeklaefnckpidbodff;;
    8) extid=jaoebcikabjppaclpgbodmmnfjihdngk;;
    9) extid=ghlpmldmjjhmdgmneoaibbegkjjbonbk;;
    10) extid=ddfbkhpmcdbciejenfcolaaiebnjcbfc;;
    11) extid=jfbecfmiegcjddenjhlbhlikcbfmnafd;;
    12) extid=jjpmjccpemllnmgiaojaocgnakpmfgjg;;
    13) read -r -p "enter extension id>" extid;;
    *) echo "invalid option" ;;
    esac
    echo "$extid" | grep -qE '^[a-z]{32}$' && chmod 000 "/home/chronos/user/Extensions/$extid" && kill -9 $(pgrep -f "\-\-extension\-process") || "invalid input"
}

hardenableext() {
    echo "Please choose the extension you wish to enable."
    echo "(1) GoGuardian"
    echo "(2) Securly Filter"
    echo "(3) LightSpeed Filter"
    echo "(4) Cisco Umbrella"
    echo "(5) ContentKeeper Authenticator"
    echo "(6) Hapara"
    echo "(7) iboss"
    echo "(8) LightSpeed Classroom"
    echo "(9) Blocksi"
    echo "(10) Linewize"
    echo "(11) Securly Classroom"
    echo "(12) Impero"
    echo "(13) put extension ID in manually"
    read -r -p "> (1-13): " choice
    case "$choice" in
    1) extid=haldlgldplgnggkjaafhelgiaglafanh;;
    2) extid=iheobagjkfklnlikgihanlhcddjoihkg;;
    3) extid=adkcpkpghahmbopkjchobieckeoaoeem;;
    4) extid=jcdhmojfecjfmbdpchihbeilohgnbdci;;
    5) extid=jdogphakondfdmcanpapfahkdomaicfa;;
    6) extid=aceopacgaepdcelohobicpffbbejnfac;;
    7) extid=kmffehbidlalibfeklaefnckpidbodff;;
    8) extid=jaoebcikabjppaclpgbodmmnfjihdngk;;
    9) extid=ghlpmldmjjhmdgmneoaibbegkjjbonbk;;
    10) extid=ddfbkhpmcdbciejenfcolaaiebnjcbfc;;
    11) extid=jfbecfmiegcjddenjhlbhlikcbfmnafd;;
    12) extid=jjpmjccpemllnmgiaojaocgnakpmfgjg;;
    13) read -r -p "enter extension id>" extid;;
    *) echo "invalid option" ;;
    esac
    echo "$extid" | grep -qE '^[a-z]{32}$' && chmod 777 "/home/chronos/user/Extensions/$extid" && kill -9 $(pgrep -f "\-\-extension\-process") || "invalid input"
}

softdisableext() {
    echo "Extensions will stay disabled until you press Ctrl+c or close this tab"
    while true; do
        kill -9 $(pgrep -f "\-\-extension\-process") 2>/dev/null
        sleep 0.5
    done
}
install_crouton() {
    doas "bash <(curl -SLk https://goo.gl/fd3zc) -t xfce -r bullseye"
    touch /mnt/stateful_partition/crouton
}
start_crouton() {
    doas "startxfce4"
}
if [ "$0" = "$BASH_SOURCE" ]; then
    stty sane
    main
fi
