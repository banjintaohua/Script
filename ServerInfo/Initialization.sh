#!/usr/bin/bash

# 获取文件名(文件名被命名为了服务器 IP)
# shellcheck disable=SC2039
if ! [[ $1 =~ ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.sh$ ]]; then
  echo "解析文件名失败, 文件名: $1 需为 IP 地址"
  exit
else
  # shellcheck disable=SC2034
  TARGET=$(echo "$1" | grep -oE '^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}')
fi

# iTerm2 兼容 sz rz 命令
export LC_CTYPE=en_US

