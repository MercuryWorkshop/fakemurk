#!/bin/bash

{
    until tpm_manager_client take_ownership; do
        echo "failed to take ownership"
    done

    {
        while true; do
            cryptohome --action=remove_firmware_management_parameters >/dev/null 2>&1
        done
    } &
    {
        while true; do
            vpd -i RW_VPD -s block_devmode=0 >/dev/null 2>&1
            sleep 5
        done
    } &
} &
