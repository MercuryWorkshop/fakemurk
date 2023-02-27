#!/usr/bin/env bash

function softdisableext() { # calling it "soft disable" because it still takes up storage space
    if [ ! -d "/home/chronos/.extstore" ]; then
        mkdir /home/chronos/.extstore
    fi
    mv /home/chronos/user/Extensions/$1 /home/chronos/.extstore/
    chmod 000 /home/chronos/user/Extensions/$1
}

function softenableext() {
    chmod 777 /home/chronos/user/Extensions/$1
    mv /home/chronos/.extstore/$1 /home/chronos/user/Extensions/$1
}

function disableext() {
    rm /home/chronos/user/Extensions/$1/*
    chmod 000 /home/chronos/user/Extensions/$1
}

function enableext() {
    rm /home/chronos/user/Extensions/$1/*
    chmod 000 /home/chronos/user/Extensions/$1
}