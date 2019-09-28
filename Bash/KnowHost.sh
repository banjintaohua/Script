#!/usr/bin/bash

# 删除原始记录
if [ $# -gt 0 ]; then
   ssh-keygen -R "$1"
fi
