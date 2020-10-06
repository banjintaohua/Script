#!/bin/bash

SSHPASS='/Users/sea/Documents/Scrip/AutoLogin/sshpass'

for config in "$SSHPASS"/config/conf.d/*.sh; do
    source "$config"
done
