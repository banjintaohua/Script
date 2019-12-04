#!/usr/bin/bash

# 跳板机
# shellcheck disable=SC2034
JUMP_SERVER_USER="uese"
JUMP_SERVER="server"
JUMP_SERVER_PORT="port"
JUMP_SERVER_PASSWORD="password"
JUMP_PROXY_PORT="port"
JUMP_KNOW_HOST='host'

# 目标机器
TARGET_USER="user"
TARGET_SERVER="server"
TARGET_SERVER_PORT="port"
TARGET_SERVER_PASSWORD="password"
TARGET_PROXY_PORT="port"


# 数据库代理端口
DB_PROXY_PORTS=(port port)

# 所有隧道代理端口
TUNNEL_PROXY_PORTS=(port port)