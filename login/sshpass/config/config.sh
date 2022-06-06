#!/bin/bash

SSHPASS='/Users/sea/Developer/Scrip/login/sshpass'

for config in "$SSHPASS"/config/conf.d/*.sh; do
    source "$config"
done
