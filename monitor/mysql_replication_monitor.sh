#!/bin/bash
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
mysqlHost="$MYSQL_HOST"
mysqlPort="$MYSQL_PORT"
mysqlUser="$MYSQL_USER"
mysqlPassword="$MYSQL_PASSWORD"
threshold=50
dump=0

# 失败立即退出
set -e
set -o pipefail

# 使用说明
function help() {
    sed -rn 's/^### ?//p' "$0"
    exit 1
}

function main() {
    slaveStatus=$(mysql -h"$mysqlHost" -P"$mysqlPort" -u"$mysqlUser" -p"$mysqlPassword" -e "show slave status\G")

    # 主从数据不一致告警
    if [[ $(echo "$slaveStatus" | grep 'Slave_SQL_Running:' | awk '{print $NF}') != "Yes" ]]; then
        curl --location --request POST "$BARK_URL" \
            --form "title=$mysqlHost mysql slave SQL error" \
            --form "body=$slaveStatus" \
            --form "group=monitor" > /dev/null 2>&1
    fi

    # 主从同步延迟告警
    if [[ $(echo "$slaveStatus" | grep 'Seconds_Behind_Master:' | awk '{print $NF}') != "$threshold" ]]; then
        curl --location --request POST "$BARK_URL" \
            --form "title=$mysqlHost the replication SQL thread is behind processing the source's binary log ${threshold}s" \
            --form "body=$slaveStatus" \
            --form "group=monitor" > /dev/null 2>&1
    fi

    # 转存当前主从信息
    if [[ $dump -eq 1 ]]; then
        dumpFile="/tmp/mysql_replication_monitor.dump."$(date +%Y-%m-%d-%H-%m-%S)
        echo "$slaveStatus" >> "$dumpFile"

        processlist=$(mysql -h"$mysqlHost" -P"$mysqlPort" -u"$mysqlUser" -p"$mysqlPassword" -e "show full processlist")
        echo "$processlist" >> "$dumpFile"
    fi
}

# 解析脚本参数
args=$(
    getopt \
        --option u::h::P::p::t::d \
        --long help,user::,host::,port::,password::,threshold::,dump \
        -- "$@"
)
eval set -- "$args"
test $# -le 1 && help && exit 1

# 处理脚本参数
while true; do
    case "$1" in
        --help)
            help
            break
            ;;
        -u | --user)
            mysqlUser=$2
            shift 2
            ;;
        -h | --host)
            mysqlHost=$2
            shift 2
            ;;
        -P | --port)
            mysqlPort=$2
            shift 2
            ;;
        -p | --password)
            mysqlPassword=$2
            shift 2
            ;;
        -t | --threshold)
            threshold=$2
            shift 2
            ;;
        -d | --dump)
            dump=1
            shift
            ;;
        --)
            shift
            break
            ;;
    esac
done

main
