#!/bin/bash

SSHPASS='/Users/sea/Developer/Scrip/login/sshpass'
SHELL_TYPE='bash'

for config in "$SSHPASS"/config/conf.d/*.sh; do
    source "$config"
done
