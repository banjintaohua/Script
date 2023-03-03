#!/bin/bash

SSHPASS='/Users/sea/Developer/Scrip/backup'

for config in "$SSHPASS"/config/conf.d/*.sh; do
    source "$config"
done
