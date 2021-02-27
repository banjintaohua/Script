#!/bin/bash

SSHPASS='/Users/sea/Documents/Scrip/login/sshpass'

for config in "$SSHPASS"/config/conf.d/*.sh; do
    source "$config"
done
