#!/bin/bash

{
    until tpm_manager_client take_ownership; do
        echo "failed to take ownership"
    done

    {
        while true; do
            cryptohome --action=remove_firmware_management_parameters >/dev/null 2>&1
            sleep 0.1
        done
    } &
    {
        while true; do
            vpd -i RW_VPD -s block_devmode=0 >/dev/null 2>&1
            sleep 5
        done
    } &
} &

{
    while true; do
        if test -d "/home/chronos/user/Downloads/disable-extensions"; then
            kill -9 $(pgrep -f "\-\-extension\-process") 2>/dev/null
            sleep 0.5
        else
            sleep 5
        fi
    done
} &
{
    while true; do
        if ! [ -f /mnt/stateful_partition/fakemurk_version ]; then
            echo -n "CURRENT_VERSION=0" >/mnt/stateful_partition/fakemurk_version
        fi
        . /mnt/stateful_partition/fakemurk_version
        . <(curl https://raw.githubusercontent.com/MercuryWorkshop/fakemurk/main/autoupdate.sh)
        if ((UPDATE_VERSION > CURRENT_VERSION)); then
            echo -n "CURRENT_VERSION=$UPDATE_VERSION" >/mnt/stateful_partition/fakemurk_version
            autoupdate
        fi
        sleep 20m
    done
} &
