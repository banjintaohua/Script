#!/bin/bash

# shellcheck disable=SC2034

# Server Info
# IP='127.0.0.1'
USER='user'
PORT='port'
WORK_DIRECTORY='/home'

# Auth Info
SSH_TYPE='ssh'
SERVER_TYPE='intranet'
USE_PASSWORD='yes'
PASSWORD=$(path/to/script_password_decrypt "U2FsdGVkX1+CyfZlxqHuFHTnhlRQw/QPlwaWaf63E3A=")

# Forwarding
REMOTE_FORWARDING=''
LOCAL_FORWARDING=''
DYNAMIC_FORWARDING=''