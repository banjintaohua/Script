#!/usr/bin/env bash
###
### Filename: mysql_replication_monitor.sh
### Author: banjintaohua
### Version: 1.0.0
###
### Description:
###   monitoring mysql replication status.
###
### Usage: mysql_replication_monitor.sh [options...]
###
### Options:
###   --help            show help message.
###   -u, --user        user for login mysql.
###   -h, --host        connect to mysql host.
###   -P, --port        port number to use for connection.
###   -p, --password    password to use when connecting to server.
###   -t, --threshold   threshold for Seconds_Behind_Master
###   -d, --dump        dump slava status and full processlist

# 读取配置信息
source "$(dirname "$0")"/config/config.sh
THRESHOLD=50
DUMP=0

# 失败立即退出
set -e
set -o pipefail

# 使用说明
function help() {
    sed -rn 's/^### ?//p' "$0"
    exit 1
}

function main() {
    slave_status=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "show slave status\G")

    # 主从数据不一致告警
    if [[ $(echo "$slave_status" | grep 'Slave_SQL_Running:' | awk '{print $NF}') != "Yes" ]]; then
        curl --location --request POST "$BARK_URL" \
            --form "title=$MYSQL_HOST mysql slave SQL error" \
            --form "body=$slave_status" \
            --form "group=monitor" > /dev/null 2>&1
    fi

    # 主从同步延迟告警
    if [[ $(echo "$slave_status" | grep 'Seconds_Behind_Master:' | awk '{print $NF}') != "$THRESHOLD" ]]; then
        curl --location --request POST "$BARK_URL" \
            --form "title=$MYSQL_HOST the replication SQL thread is behind processing the source's binary log ${THRESHOLD}s" \
            --form "body=$slave_status" \
            --form "group=monitor" > /dev/null 2>&1
    fi

    # 转存当前主从信息
    if [[ $DUMP -eq 1 ]]; then
        dump_file="/tmp/mysql_replication_monitor.dump."$(date +%Y-%m-%d-%H-%m-%S)
        echo "$slave_status" >> "$dump_file"

        processlist=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "show full processlist")
        echo "$processlist" >> "$dump_file"
    fi
}

# 解析脚本参数
args=$(
    getopt \
        --options u:h:P:p:t:d \
        --longoptions help,user:,host:,port:,password:,threshold:,dump \
        -- "$@"
)
eval set -- "${args}"
test $# -le 1 && help && exit 1

# 处理脚本参数
while true; do
    case "$1" in
        --help)
            help
            break
            ;;
        -u | --user)
            MYSQL_USER=$2
            shift 2
            ;;
        -h | --host)
            MYSQL_HOST=$2
            shift 2
            ;;
        -P | --port)
            MYSQL_PORT=$2
            shift 2
            ;;
        -p | --password)
            MYSQL_PASSWORD=$2
            shift 2
            ;;
        -t | --threshold)
            THRESHOLD=$2
            shift 2
            ;;
        -d | --dump)
            DUMP=1
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "invalid argument";
            exit 1
            ;;
    esac
done

main
