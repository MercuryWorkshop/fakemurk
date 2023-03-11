#!/bin/bash


{
    until tpm_manager_client take_ownership; do
        echo "failed to take ownership"
    done


    {

        launch_racer(){
           echo launching racer at $(date)
           {
                while true; do
                    cryptohome --action=remove_firmware_management_parameters >/dev/null 2>&1
                done
           } &
           RACERPID=$!
        }
        launch_racer
        while true; do
              cryptohome --action=remove_firmware_management_parameters >/dev/null 2>&1
              echo checking cryptohome status
              if [ "$(cryptohome --action=is_mounted)" == "true" ]; then
                if ! [ -z $RACERPID ]; then
                   echo "logged in, waiting to kill racer"
                   sleep 1m
                   kill -9 $RACERPID
                   echo "racer terminated at $(date)"
                   RACERPID=
                fi
              else
                if [ -z $RACERPID ]; then 
                    launch_racer
                fi
              fi
              sleep 30
        done
    } &

    {
        while true; do
            vpd -i RW_VPD -s block_devmode=0 >/dev/null 2>&1
            sleep 5m
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
            echo -n "CURRENT_VERSION=3" >/mnt/stateful_partition/fakemurk_version
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
