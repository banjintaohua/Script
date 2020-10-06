#!/usr/bin/bash

# 查看隧道
function intranet_list() {
    line=$(netstat -an | grep -c -E "127.0.0.1.($INTRANET_PROXY_PORT).*LISTEN")
    if [[ $line =~ ^[\ ]*0 ]]; then
        echo '未设置内网服务器隧道'
    else
        echo "已设置内网服务器隧道"
        netstat -an | grep -E "127.0.0.1.($INTRANET_PROXY_PORT).*LISTEN"
    fi
    return "$line"
}

# 关闭隧道
function intranet_kill() {
    netstat -an | grep -E "($INTRANET_PROXY_PORT).*LISTEN"
    ps axu | grep -E "ssh.*127.0.0.1:$INTRANET_PROXY_PORT" | grep -v grep | awk '{print $2}' | xargs -I {} kill {}
    line=$(netstat -an | grep -c -E "($INTRANET_PROXY_PORT).*LISTEN")
    if [[ $line =~ ^[\ ]*0 ]]; then
        echo '清理内网服务器隧道成功'
    else
        echo "清理内网服务器隧道失败"
    fi
}

# 设置隧道
function set_proxy() {
    intranet_list
    line=$?
    if [[ $line -eq 0 ]]; then
        intranet_kill

        # 删除原始记录
        ssh-keygen -R "[$JUMP_SERVER]:$JUMP_SERVER_PORT"

        echo "正在设置隧道"
        source "$(dirname "$0")"/../jump.sh

        # 建立代理机器的隧道
        /usr/bin/expect -d << EXPECT
          set timeout -1
          spawn ssh $INTRANET_SERVER_USER@$INTRANET_SERVER -p $INTRANET_SERVER_PORT -f -N -D 127.0.0.1:$INTRANET_PROXY_PORT -o \"ProxyCommand=nc -x 127.0.0.1:$JUMP_PROXY_PORT %h %p\"
          expect "password:"
          send "$INTRANET_SERVER_PASSWORD\n"
          expect eof
EXPECT

        clear

        if [[ $(netstat -an | grep -c "$INTRANET_PROXY_PORT") -lt 1 ]]; then
            echo "设置内网服务器隧道失败"
            exit
        else
            echo "执行 : tunnel list 查看内网服务器隧道"
            echo "执行 : tunnel kill 删除内网服务器隧道"
        fi
    fi
    echo '已设置内网服务器隧道'
}

# 读取服务器信息
source "$(dirname "$0")"/../config/config.sh

# 判断执行的命令
if [[ $# == 1 ]]; then
    case $1 in
        list)
            intranet_list
            ;;
        kill)
            intranet_kill
            ;;
        *)
            echo '参数非法'
            ;;
    esac
else
    set_proxy
fi
