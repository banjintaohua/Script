#!/bin/bash

SSHPASS='/Users/sea/Developer/Scrip/monitor'

for config in "$SSHPASS"/config/conf.d/*.sh; do
    source "$config"
done
