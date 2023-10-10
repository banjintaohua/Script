#!/usr/bin/env bash
###
### Filename: mongodb_backup.sh
### Author: banjintaohua
### Version: 1.0.0
###
### Description:
###   mongodb backup
###
### Usage: mongodb_backup.sh [options...]
###
### Options:
###   -h, --help         show help message.
###   -d, --max-days     days of data retention, the default is keep 7 days
###   -p, --path         data saving path, the default is /tmp/mongodb_backup

# 读取配置信息
source "$(dirname "$0")"/config/config.sh
BACKUP_COLLECTIONS="results"
MAX_DAYS=7
DATA_SAVING_PATH=/tmp/mongodb_backup

# 失败立即退出
set -e
set -o pipefail

function help() {
    sed -rn 's/^### ?//p' "$0"
    exit 1
}

function backup() {

    # 解析需要备份的集合
    test -z "$BACKUP_COLLECTIONS" && echo 'collections is required' && exit 1
    IFS=$','
    collections=($BACKUP_COLLECTIONS)

    # 按集合粒度备份文件
    for collection in  ${collections[*]}; do
        mongodump --host="$MONGODB_HOST" --port="$MONGODB_PORT" \
          --username="$MONGODB_USER" --password="$MONGODB_PASSWORD" --authenticationDatabase="admin" \
          --db="$MONGODB_DATABASE" --collection="$collection" \
          --archive="$DATA_SAVING_PATH" --gzip
    done
}

function main() {
    # 清理旧数据
    test -d $DATA_SAVING_PATH || mkdir -p $DATA_SAVING_PATH
    find "$DATA_SAVING_PATH" -mtime +"$MAX_DAYS" -type f -exec rm -f '{}' \;

    # 备份
    backup
}

# 解析脚本参数
args=$(
    getopt \
        --options hd:p: \
        --longoptions help,max-days:path: \
        -- "$@"
)
eval set -- "${args}"
test $# -le 1 && help && exit 1

# 处理脚本参数
while true; do
    case "$1" in
        -h | --help)
            help
            break
            ;;
        -d | --max-days)
            MAX_DAYS=$2
            shift 2
            ;;
        -p | --path)
            DATA_SAVING_PATH=$2
            shift 2
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
