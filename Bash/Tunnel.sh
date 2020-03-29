#!/usr/bin/bash

# 查看隧道
function tunnel_list() {
    line=$(netstat -an | grep -c -E "127.0.0.1.($TARGET_PROXY_PORT).*LISTEN")
    if [[ $line =~ ^[\ ]*0 ]]; then
        echo '未设置隧道'
    else
        echo "已设置隧道"
        netstat -an | grep -E "127.0.0.1.($TARGET_PROXY_PORT).*LISTEN"
    fi
    return "$line"
}

# 关闭隧道
function tunnel_kill() {
    netstat -an | grep -E "($TARGET_PROXY_PORT).*LISTEN"
    ps axu | grep -E "ssh.*127.0.0.1:$TARGET_PROXY_PORT" | grep -v grep | awk '{print $2}' | xargs -I {} kill {}
    line=$(netstat -an | grep -c -E "($TARGET_PROXY_PORT).*LISTEN")
    if [[ $line =~ ^[\ ]*0 ]]; then
        echo '清理隧道成功'
    else
        echo "清理隧道失败"
    fi
}

# 设置隧道
function set_proxy () {
  tunnel_list
  line=$?
  if [[ $line -eq 0 ]]; then
      tunnel_kill
      echo "正在设置隧道"
      source $(dirname "$0")/Jump.sh
      /usr/bin/expect -d >> ~/Documents/Config/Log/tunnel.log 2>&1 <<EXPECT
          set timeout -1
          spawn ssh $TARGET_USER@$TARGET_SERVER -p $TARGET_SERVER_PORT -f -N -D 127.0.0.1:$TARGET_PROXY_PORT -o \"ProxyCommand=nc -X 5 -x 127.0.0.1:4790 %h %p\"
          expect "password:"
          send "$TARGET_SERVER_PASSWORD\n"
          expect eof
EXPECT

      # 删除原始记录
      source $(dirname "$0")/KnowHost.sh "$JUMP_KNOW_HOST"
      clear

      if [[ $(netstat -an | grep -c "$TARGET_PROXY_PORT") -lt 1 ]]; then
          echo "设置隧道失败"
          exit
      else
          echo "执行 : tunnel list 查看隧道"
          echo "执行 : tunnel kill 删除隧道"
      fi
  fi
  echo '已设置隧道'
}


# 读取服务器信息
# shellcheck disable=SC1090
# shellcheck disable=SC2046
source $(dirname "$0")/../ServerInfo/ServerInfo.sh

# 判断执行的命令
if [[ $# == 1 ]]; then
    case $1 in
        list )
            tunnel_list
            ;;
        kill )
            tunnel_kill
            ;;
        *    )
            echo '参数非法'
            ;;
    esac
 else
    set_proxy
 fi