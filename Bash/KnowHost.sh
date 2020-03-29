#!/usr/bin/bash

# 删除原始记录
if [ $# -gt 0 ]; then
    if [[  $(grep -c "$1" < ~/.ssh/known_hosts) -ge 1 ]]; then
        ssh-keygen -R "$1"
    fi
fi
