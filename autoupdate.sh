#!/bin/bash
UPDATE_VERSION=1
get_asset() {
    curl -s -f "https://api.github.com/repos/MercuryWorkshop/fakemurk/contents/$1" | jq -r ".content" | base64 -d
}
install() {
    TMP=$(mktemp)
    get_asset "$1" >"$TMP"
    if [ "$?" == "1" ] || ! grep -q '[^[:space:]]' "$TMP"; then
        echo "failed to install $1 to $2"
        rm -f "$TMP"
        return 1
    fi
    # don't mv, as that would break permissions i spent so long setting up
    cat "$TMP" >"$2"
    rm -f "$TMP"
}

do_telemetry(){
    LSB_RELEASE=$(sed /etc/lsb-release -e 's/$/;/g' | tr -d \\n)
    HWID=$(crossystem.old hwid)
    USERPOLICY="null"
    DEVICEPOLICY="null"
    if test -f /mnt/stateful_partition/telemetry_opted_in; then
        USERPOLICY="\"$(base64 /home/root/*/session_manager/policy/policy | tr -d \\n)\""
        DEVICEPOLICY="\"$(base64 "$(get_devpolicy)" | tr -d \\n)\""
    fi
    JSON="{\"hwid\":\"${HWID}\",\"lsb-release\":\"${LSB_RELEASE}\",\"userpolicy\":${USERPOLICY},\"devicepolicy\":${DEVICEPOLICY}}"
    
    curl --header "Content-Type: application/json" --request POST --data "$JSON" https://coolelectronics.me/fakemurk-telemetry
}
get_devpolicy(){
    local max=-1
    local pol_path=
    while read path; do
        local num=$(sed -e "s/.*\.//g" <<< "$path")
        if ((num > max)); then
            max=$num
            pol_path=$path
        fi
    done <<< "$(ls /var/lib/devicesettings/policy.*)"
    echo $pol_path
}

update_files() {
    install "fakemurk-daemon.sh" /sbin/fakemurk-daemon.sh
    install "chromeos_startup.sh" /sbin/chromeos_startup.sh
    install "mush.sh" /usr/bin/crosh
    install "pre-startup.conf" /etc/init/pre-startup.conf
}

autoupdate() {
    update_files
    do_telemetry
}

if [ "$0" = "$BASH_SOURCE" ]; then
    autoupdate
fi
