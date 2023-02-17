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

if [[ -n $IP ]]; then
    SERVER=$IP
fi

# 删除原始记录
sed -in "s/.*$JUMP_SERVER.*//g" ~/.ssh/known_hosts
sed -in '/^$/d' ~/.ssh/known_hosts
if [[ $(grep -c "$JUMP_SERVER" < ~/.ssh/known_hosts) -ge 1 ]]; then
    # 通过 ssh-keygen 会有各种转义的问题，改为使用 sed
    # ssh-keygen -R "[$JUMP_SERVER]:$JUMP_SERVER_PORT"
    echo "sed -in \"s/.*$JUMP_SERVER.*//g\" ~/.ssh/known_hosts | sed -in \"/^$/d\""
    grep "$JUMP_SERVER" < ~/.ssh/known_hosts
fi

FORWARDING=''
if [[ -n "$REMOTE_FORWARDING" ]]; then
    FORWARDING="-R $REMOTE_FORWARDING"
fi

if [[ -n "$LOCAL_FORWARDING" ]]; then
    FORWARDING="-L $LOCAL_FORWARDING"
fi

if [[ -n "$DYNAMIC_FORWARDING" ]]; then
    FORWARDING="-D $DYNAMIC_FORWARDING"
fi

# 再次执行 bash 是 nologin 模式，可以使用 bash -l 启动 login shell

# 连接类型
if [[ "$SSH_TYPE" == 'mosh' || "$2" == 'mosh' ]]; then
    SSH_TYPE='mosh'
    sshpass -p "$PASSWORD" \
        mosh "$USER@$SERVER" \
        --ssh="ssh -p $PORT" \
        "$SHELL_TYPE -l"
fi

# 内网服务器
if [ "$SERVER_TYPE" == 'intranet' ]; then
    # 判断是否需要使用密码登录
    if [ "$USE_PASSWORD" == 'yes' ]; then
        sshpass -p "$PASSWORD" \
            ssh "$USER@$SERVER" -p "$PORT" \
            -o "ServerAliveInterval=60" \
            -o "StrictHostKeyChecking=no" \
            -o "UserKnownHostsFile /dev/null" \
            -o "ProxyCommand=nc -x 127.0.0.1:$JUMP_PROXY_PORT %h %p" \
            -v \
            -t \
            "cd $WORK_DIRECTORY; clear; $SHELL_TYPE -l"
    else
        sshpass -p "$JUMP_SERVER_PASSWORD" \
            ssh "$JUMP_SERVER_USER@$JUMP_SERVER" -p "$JUMP_SERVER_PORT" \
            -o "ServerAliveInterval=60" \
            -o "StrictHostKeyChecking=no" \
            -o "UserKnownHostsFile /dev/null" \
            -v \
            -t \
            "ssh $USER@$SERVER -p $PORT -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile /dev/null' -v -t 'cd $WORK_DIRECTORY; clear; $SHELL_TYPE -l'"
    fi
else
    if [ "$USE_PASSWORD" == 'yes' ]; then
        sshpass -p "$PASSWORD" \
            ssh "$USER@$SERVER" -p "$PORT" \
            -o "ServerAliveInterval=60" \
            -o "StrictHostKeyChecking=no" \
            -o "UserKnownHostsFile /dev/null" \
            -v \
            -t \
            "cd $WORK_DIRECTORY; export ENV=/etc/profile; clear; $SHELL_TYPE -l"
    else
        ssh "$USER@$SERVER" -p "$PORT" \
            -o "ServerAliveInterval=60" \
            -o "StrictHostKeyChecking=no" \
            -o "UserKnownHostsFile /dev/null" \
            $FORWARDING \
            -v \
            -t \
            "cd $WORK_DIRECTORY; export ENV=/etc/profile; clear; $SHELL_TYPE -l"
    fi
fi
