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

# 获取文件名(文件名被命名为了服务器 IP)
# shellcheck disable=SC2039
if ! [[ $1 =~ ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.sh$ ]]; then
  echo "解析文件名失败, 文件名: $1 需为 IP 地址"
  exit
else
  TARGET=$(echo "$1" | grep -oE '^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}')
fi

# iTerm2 兼容 sz rz 命令
export LC_CTYPE=en_US