#!/bin/bash

# 读取服务器信息
source "$(dirname "$0")"/config/config.sh

# 判断执行的命令
if [ $# -lt 1 ]; then
    echo "**************************"
    # shellcheck disable=SC2153
    for ((i = 0; i < ${#SERVERS[@]}; i++)); do
        echo "$i: ${SERVERS[$i]}"
    done
    echo "**************************"

    read -r -p "请选择需要登录的服务器 : " INDEX
    echo "********************************************"

    if [[ $INDEX =~ [^0-9]+ ]]; then
        echo "请选择正确范围的服务器"
        echo "********************************************"
        exit 1
    fi

    SERVER=${SERVERS[$INDEX]}

else
    SERVER=$1
fi

# 提示连接的服务器
echo "您选择的服务器为 : $SERVER"
echo "********************************************"

# 获取 IP 的配置文件
CONFIG_FILE="$SSHPASS/config/servers/$SERVER.sh"
if ! [ -f "$CONFIG_FILE" ]; then
    echo "无法获取 $SERVER 的配置文件, 请确认 $CONFIG_FILE 文件是否存在"
    exit 1
else
    source "$CONFIG_FILE"
fi

# 删除原始记录
KNOW_HOSTS="\[$JUMP_SERVER\]:$JUMP_SERVER_PORT"
if [[ $(grep -c "$KNOW_HOSTS" < ~/.ssh/known_hosts) -ge 1 ]]; then
    ssh-keygen -R "'$KNOW_HOSTS'"
fi

# 内网服务器
if [ "$SERVER_TYPE" == 'intranet' ]; then
    # 判断是否需要使用密码登录
    if [ "$USE_PASSWORD" == 'yes' ]; then
        sshpass -p "$PASSWORD" \
            ssh "$USER@$SERVER" -p "$PORT" \
            -o 'StrictHostKeyChecking=no' \
            -o "ProxyCommand=nc -x 127.0.0.1:$JUMP_PROXY_PORT %h %p" \
            -v
    else
        sshpass -p "$JUMP_SERVER_PASSWORD" \
            ssh "$JUMP_SERVER_USER@$JUMP_SERVER" -p "$JUMP_SERVER_PORT" \
            -tt \
            -o 'StrictHostKeyChecking=no' \
            -v \
            ssh "$USER@$SERVER" -p "$PORT" \
            -o 'StrictHostKeyChecking=no' \
            -v
    fi
else
    if [ "$USE_PASSWORD" == 'yes' ]; then
        sshpass -p "$PASSWORD" \
            ssh "$USER@$SERVER" -p "$PORT" \
            -o 'StrictHostKeyChecking=no' \
            -v
    else
        ssh "$USER@$SERVER" -p "$PORT" \
            -o 'StrictHostKeyChecking=no' \
            -v
    fi
fi
