#!/bin/bash
###
### Filename: disk_monitor.sh
### Author: banjintaohua
### Version: 1.0.0
###
### Description:
###   monitoring disk usage.
###
### Usage: disk_monitor.sh [options...]
###
### Options:
###   -h, --help         show help message.
###   -m, --mount-point  mount point
###   -t, --threshold    threshold

# 读取配置信息
mountPoint="/"
threshold=80
source "$(dirname "$0")"/config/config.sh

# 失败立即退出
set -e
set -o pipefail

# 使用说明
function help() {
    sed -rn 's/^### ?//p' "$0"
    exit 1
}

# 磁盘使用率过高则发送告警
function main() {
    diskUsage=$(df -h | grep -e " $mountPoint$" | awk '{print $5}' | sed 's/%//g')
    if [[ $diskUsage -ge $threshold ]]; then
        localIp=$(ifconfig eth0 | grep 'inet ' | awk '{print $2}')
        curl --location --request POST "$BARK_URL" \
            --form "title=$localIp $mountPoint disk usage reaches $diskUsage%" \
            --form "body=please release the disk space" \
            --form "group=monitor" > /dev/null 2>&1
    fi
}

# 解析脚本参数
args=$(/usr/local/opt/gnu-getopt/bin/getopt --option hm:t: --long help,mount-point:,threshold: -- "$@")
eval set -- "$args"
test $# -le 1 && help && exit 1

# 处理脚本参数
while true; do
    case "$1" in
        -h | --help)
            help
            break
            ;;
        -m | --mount-point)
            mountPoint=$2
            shift 2
            ;;
        -t | --threshold)
            threshold=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
    esac
done

main
