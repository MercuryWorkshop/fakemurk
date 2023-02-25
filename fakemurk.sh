#!/bin/bash











traps() {
    set -e
    trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
    trap 'echo "\"${last_command}\" command failed with exit code $?. THIS IS A BUG, REPORT IT"' EXIT
}

csys() {
    if test -f "/usr/bin/crossystem.old"; then
        /usr/bin/crossystem.old
    else
        /usr/bin/crossystem
    fi
}

raw_crossystem_sh() {
    base64 -d <<-EOF | bunzip2 -dc
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
EOF
}

sed_escape() {
    echo -n "$1" | while read -n1 ch; do
        if [[ -z "$ch" ]]; then
            echo -n "\n"
        fi
        echo -n \\x$(printf %x \'"$ch")
    done
}
drop_crossystem_sh() {
    vals=$(crossystem_values)
    raw_crossystem_sh | sed -e "s/__SED_REPLACEME_CROSSYSTEM_VALUES/$(sed_escape "$escaped")/g" >/usr/bin/crossystem.old
}

escape() {
    case $1 in
    '' | *[!0-9]*) printf "\"$1\"" ;;
    *) printf $1 ;;
    esac
}

crossystem_values() {
    readarray -t csys_lines <<<"$(csys)"
    for element in "${csys_lines[@]}"; do
        line_stripped=$(echo "$element" | sed -e "s/#.*//g" | sed -e 's/ .*=/=/g')
        # sed 1: cuts out all chars after the #
        # sed 2: cuts out all spaces before =
        IFS='=' read -r -a pair <<<"$line_stripped"

        key=$(echo ${pair[0]})
        # cut out all characters after an instance of 2 spaces in a row
        val="$(echo ${pair[1]} | sed -e 's/  .*//g')"
        echo "$key=$(escape "$val")"
    done
}

main() {
    traps
    mv /usr/bin/crossystem /usr/bin/crossystem.old
    drop_crossystem_sh
    trap - EXIT
    exit

}

if [ "$0" = "$BASH_SOURCE" ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit
    fi
    main
fi
