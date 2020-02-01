#!/usr/bin/bash

# 查看隧道
function tunnel_list() {
    line=$(netstat -an | grep -c -E "127.0.0.1.($PORTS).*LISTEN")
    if [[ $line =~ ^[\ ]*0 ]]; then
        echo '未设置隧道'
    else
        echo "已设置 $line 条隧道"
        netstat -an | grep -E "127.0.0.1.($PORTS).*LISTEN"
    fi
}

# 关闭隧道
function tunnel_kill() {
    netstat -an | grep -E "($PORTS).*LISTEN"
    # shellcheck disable=SC2009
    ps axu | grep -E "ssh.*127.0.0.1:$PORTS" | grep -v grep | awk '{print $2}' | xargs -I {} kill {}
    line=$(netstat -an | grep -c -E "($PORTS).*LISTEN")
    if [[ $line =~ ^[\ ]*0 ]]; then
        echo '清理隧道成功'
    else
        echo "清理隧道失败, 仍运行 $line 条隧道"
    fi
}

# 设置隧道
function set_proxy () {
    line=$(netstat -an | grep -c -E "127.0.0.1.($PORTS).*LISTEN")
    if [[ $line -gt 0 ]]; then
        echo "已设置 $line 条隧道"
    else
        source /Users/sea/Documents/Scrip/Bash/Jump.sh
        for PORT in ${SCENE[*]} ; do
            echo "正在设置隧道, 端口: $PORT"
            nohup /usr/bin/expect /Users/sea/Documents/Scrip/Expect/Forward.expect "${PORT}" > /Users/sea/Documents/Config/Log/"$OPTION".expect.nohup 2>&1 &
        done
        echo "执行 : $OPTION list 查看隧道"
        echo "执行 : $OPTION kill 删除隧道"
    fi
}

# 获取目标端口
function get_param() {
   case $1 in
      db )
          OPTION='db'
          SCENE=${DB_PROXY_PORTS[*]}
          ;;
      tunnel )
          OPTION='tunnel'
          SCENE=${TUNNEL_PROXY_PORTS[*]}
          ;;
      *    )
          echo '参数非法'
          ;;
  esac
}

# 设置目标端口
function set_param() {
  for PORT in ${SCENE[*]} ; do
      if [ -z "$PORTS" ]; then
          PORTS=$PORT
      else
          PORTS=$PORTS"|"$PORT
      fi
  done
}

# 执行操作
function action() {
    case $1 in
        list )
            tunnel_list
            ;;
        kill )
            tunnel_kill
            ;;
        *    )
            echo '正在设置隧道'
            set_proxy
            ;;
    esac
}


source /Users/sea/Documents/Scrip/ServerInfo/ServerInfo.sh
get_param "$1"
set_param
action "$2"








