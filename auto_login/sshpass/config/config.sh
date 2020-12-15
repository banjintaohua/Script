#!/bin/bash

SSHPASS='/Users/sea/Documents/Scrip/auto_login/sshpass'

for config in "$SSHPASS"/config/conf.d/*.sh; do
    source "$config"
done
