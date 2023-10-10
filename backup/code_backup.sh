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
REMOTE_HOST="10.211.55.3"
REMOTE_PORT="22"
REMOTE_USER="root"
REMOTE_PATH="/home/docker/docker"
LOCAL_PATH="/tmp/docker"
MODE="pull"

# 失败立即退出
set -e
set -o pipefail

function help() {
    sed -rn 's/^### ?//p' "$0"
    exit 1
}

function main() {
    test -d $LOCAL_PATH || mkdir -p $LOCAL_PATH

    if [ $MODE == "pull" ]; then
        rsync --archive --verbose --compress --progress \
            -e "ssh -p $REMOTE_PORT" \
            "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" "$LOCAL_PATH"
    fi

    if [ $MODE == "push" ]; then
        rsync --archive --verbose --compress --progress \
            -e "ssh -p $REMOTE_PORT" \
            "$LOCAL_PATH" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH"
    fi
}

# 解析脚本参数
args=$(
    getopt \
        --options d:p:u:p:l:m::h \
        --longoptions help,host:,port:,user:,path:,local-path:,mode:: \
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
        -h | --host)
            REMOTE_HOST=$2
            shift 2
            ;;
        --port)
            REMOTE_PORT=$2
            shift 2
            ;;
        -u | --user)
            REMOTE_USER=$2
            shift 2
            ;;
        -p | --path)
            REMOTE_PATH=$2
            shift 2
            ;;
        -l | --local-path)
            LOCAL_PATH=$2
            shift 2
            ;;
        -m | --mode)
            case "$2" in
                "")
                  MODE="pull"
                  shift 2
                  ;;
                *)
                  MODE="$2"
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
