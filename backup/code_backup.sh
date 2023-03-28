#!/usr/bin/env bash
###
### Filename: code_backup.sh
### Author: banjintaohua
### Version: 1.0.0
###
### Description:
###   code backup
###
### Exit Code:
###   0  successful
###   1  error
###
### Usage: code_backup.sh [options...]
###
### Options:
###       --help         show help message.
###   -h, --host         rsync remote host, the default is 10.211.55.3
###       --port         rsync remote port, the default is 22
###   -u, --user         rsync remote user, the default is root
###   -p, --path         rsync remote path, the default is /home/docker/docker
###   -l, --local-path   rsync local path, the default is /home/docker/docker
###   -m, --mode         pull mode or push mode, the default is pull

# 配置信息
source "$(dirname "$0")"/config/config.sh
remoteHost="10.211.55.3"
remotePort="22"
remoteUser="root"
remotePath="/home/docker/docker"
localPath="/tmp/docker"
mode="pull"

# 失败立即退出
set -e
set -o pipefail

function help() {
    sed -rn 's/^### ?//p' "$0"
    exit 1
}

function main() {
    test -d $localPath || mkdir -p $localPath

    if [ $mode == "pull" ]; then
        rsync --archive --verbose --compress --progress \
            -e "ssh -p $remotePort" \
            "$remoteUser@$remoteHost:$remotePath" "$localPath"
    fi

    if [ $mode == "push" ]; then
        rsync --archive --verbose --compress --progress \
            -e "ssh -p $remotePort" \
            "$localPath" "$remoteUser@$remoteHost:$remotePath"
    fi
}

# 解析脚本参数
args=$(
    getopt \
        --option d:p:u:p:l:m::h \
        --long help,host:,port:,user:,path:,local-path:,mode:: \
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
        -h | --host)
            remoteHost=$2
            break
            ;;
        --port)
            remotePort=$2
            shift 2
            ;;
        -u | --user)
            remoteUser=$2
            shift 2
            ;;
        -p | --path)
            remotePath=$2
            shift 2
            ;;
        -l | --local-path)
            localPath=$2
            shift 2
            ;;
        -m | --mode)
            case "$2" in
                "")
                  mode="pull"
                  shift 2
                  ;;
                *)
                  mode="$2"
                  shift 2
                  ;;
            esac;;
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
