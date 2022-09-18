#!/bin/bash

# 查看隧道
function intranet_list() {
    line=$(netstat -an | grep -c -E "$INTRANET_PROXY_HOST.($INTRANET_PROXY_PORT).*LISTEN")
    if [[ $line =~ ^[\ ]*0 ]]; then
        echo '未设置内网服务器隧道'
    else
        echo "已设置内网服务器隧道"
        netstat -an | grep -E "127.0.0.1.($JUMP_PROXY_PORT).*LISTEN"
        netstat -an | grep -E "$INTRANET_PROXY_HOST.($INTRANET_PROXY_PORT).*LISTEN"
        echo "执行 : intranet kill 删除内网服务器隧道"
        echo ""
    fi
    return "$line"
}

# 关闭隧道
function intranet_kill() {
    netstat -an | grep -E "($INTRANET_PROXY_PORT).*LISTEN"
    ps axu | grep -E "ssh.*$INTRANET_PROXY_HOST:$INTRANET_PROXY_PORT" | grep -v grep | awk '{print $2}' | xargs -I {} kill {}
    line=$(netstat -an | grep -c -E "($INTRANET_PROXY_PORT).*LISTEN")
    if [[ $line =~ ^[\ ]*0 ]]; then
        echo '清理内网服务器隧道成功'
    else
        echo "清理内网服务器隧道失败"
    fi

    netstat -an | grep -E "$INTRANET_PROXY_HOST.($DBGP_CLIENT_PORT).*LISTEN"
    line=$(netstat -an | grep -c -E "$INTRANET_PROXY_HOST.($DBGP_CLIENT_PORT).*LISTEN")
    if [[ $line =~ ^[\ ]*0 ]]; then
        echo '清理内网服务器调试隧道成功'
    else
        ps -ef | grep "$INTRANET_SERVER:$IDE_LISTEN_PORT:$INTRANET_PROXY_HOST:$IDE_LISTEN_PORT" | grep -v 'grep' | awk '{printf $2}' | xargs -I {} kill {}
        line=$(netstat -an | grep -c -E "$INTRANET_PROXY_HOST.($DBGP_CLIENT_PORT).*LISTEN")
        if [[ $line =~ ^[\ ]*0 ]]; then
            echo '清理内网服务器调试隧道成功'
        else
            echo "清理内网服务器调试隧道失败"
        fi
    fi
}

# 调试隧道
function intranet_xdebug() {
    line=$(netstat -an | grep -c -E "$DEBUG_PROXY_HOST.($DBGP_CLIENT_PORT).*LISTEN")
    if [[ $line =~ ^[\ ]*0 ]]; then
        echo ''
        echo '正在设置内网服务器调试隧道'
        sshpass -p "$DBGP_PROXY_SERVER_PASSWORD" \
            ssh "$DBGP_PROXY_SERVER_USER@$DBGP_PROXY_SERVER" -p "$DBGP_PROXY_SERVER_PORT" \
            -o "ServerAliveInterval=60" \
            -o "StrictHostKeyChecking=no" \
            -L "$INTRANET_PROXY_HOST:$DBGP_CLIENT_PORT:$DBGP_PROXY_SERVER:$DBGP_CLIENT_PORT" \
            -R "$INTRANET_SERVER:$IDE_LISTEN_PORT:$INTRANET_PROXY_HOST:$IDE_LISTEN_PORT" \
            -f -N -C \
            2>&1
        echo "设置内网服务器调试隧道成功"
    else
        echo "已设置内网服务器调试隧道"
    fi

    if [[ $(netstat -an | grep -c -E "$INTRANET_PROXY_HOST.($DBGP_CLIENT_PORT).*LISTEN") -lt 1 ]]; then
        echo "内网服务器调试隧道本地端口转发失败"
    fi

    if [[ $(netstat -an | grep -c -E "$IDE_LISTEN_PORT.*LISTEN") -lt 1 ]]; then
        echo "内网服务器调试隧道远程端口转发失败"
    fi

    debug_process_id=$(ps -ef | grep "$INTRANET_SERVER:$IDE_LISTEN_PORT:$INTRANET_PROXY_HOST:$IDE_LISTEN_PORT" | grep -v 'grep' | awk '{printf $2}')
    netstat -an | grep -E "$INTRANET_PROXY_HOST.($DBGP_CLIENT_PORT).*LISTEN"
    netstat -an | grep -E "($IDE_LISTEN_PORT).*LISTEN"
    echo "执行 : kill $debug_process_id 关闭内网服务器调试隧道"
}

# 设置隧道
function set_proxy() {
    intranet_list
    line=$?
    if [[ $line -eq 0 ]]; then
        intranet_kill

        if [[ $(netstat -an | grep -c "$JUMP_PROXY_PORT") -lt 1 ]]; then
            echo "正在设置跳板机隧道"
            source "$(dirname "$0")"/jump.sh login
        else
            echo "已设置跳板机隧道"
        fi

        # 建立代理机器的隧道
        # 通过 ProxyCommand 会报错：client_loop: send disconnect: Broken pipe
        # 先用 Proxifier 代理
        sshpass -p "$INTRANET_SERVER_PASSWORD" \
            ssh "$INTRANET_SERVER_USER@$INTRANET_SERVER" -p "$INTRANET_SERVER_PORT" \
            -o "ServerAliveInterval=60" \
            -o "StrictHostKeyChecking=no" \
            -f -q -N -D "$INTRANET_PROXY_HOST:$INTRANET_PROXY_PORT" \
            > /dev/null 2>&1

        clear

        if [[ $(netstat -an | grep -c "$INTRANET_PROXY_PORT") -lt 1 ]]; then
            echo "设置内网服务器隧道失败"
            exit
        else
            echo "设置内网服务器隧道成功"
            echo "执行 : intranet list 查看内网服务器隧道"
            echo "执行 : intranet kill 删除内网服务器隧道"
            echo "建立内网服务器隧道成功，开始执行后置脚本"
            postRun > /dev/null 2>&1 &
        fi
    fi
}

# 读取服务器信息
source "$(dirname "$0")"/config/config.sh

# 判断执行的命令
if [[ $# == 1 ]]; then
    case $1 in
        list)
            intranet_list
            ;;
        kill)
            intranet_kill
            ;;
        xdebug)
            set_proxy
            intranet_xdebug
            ;;
        *)
            echo '参数非法'
            ;;
    esac
else
    set_proxy
    intranet_xdebug
fi
