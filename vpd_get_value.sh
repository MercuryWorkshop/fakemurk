#!/bin/bash

source "/mnt/stateful_partition/mwtrollinggoogleforfakemurk_VPD"

if [[ $# -eq 0 ]]; then
    echo "AWH HAIL NAH WHERE IS THE VALUE YOU WANT ME TO GET"
elif [[ $# -eq 1 ]]; then
    echo -n "${!1}"
else
    echo "gimme one value to give you. or i will continue printing this."
fi
