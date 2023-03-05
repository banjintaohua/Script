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
mongodbHost="$MONGODB_HOST"
mongodbPort="$MONGODB_PORT"
mongodbUser="$MONGODB_USER"
mongodbPassword="$MONGODB_PASSWORD"
mongodbDatabase="$MONGODB_DATABASE"

backupCollections="results"
maxDays=7
dataSavingPath=/tmp/mongodb_backup

# 失败立即退出
set -e
set -o pipefail

function help() {
    sed -rn 's/^### ?//p' "$0"
    exit 1
}

function backup() {

    # 解析需要备份的集合
    test -z "$backupCollections" && echo 'collections is required' && exit 1
    IFS=$','
    collections=($backupCollections)

    # 按集合粒度备份文件
    for collection in  ${collections[*]}; do
        mongodump --host="$mongodbHost" --port="$mongodbPort" \
          --username="$mongodbUser" --password="$mongodbPassword" --authenticationDatabase="admin" \
          --db="$mongodbDatabase" --collection="$collection" \
          --archive="$dataSavingPath" --gzip
    done
}

function main() {
    # 清理旧数据
    test -d $dataSavingPath || mkdir -p $dataSavingPath
    find "$dataSavingPath" -mtime +"$maxDays" -type f -exec rm -f '{}' \;

    # 备份
    backup
}

# 解析脚本参数
args=$(
    getopt \
        --option hd:p: \
        --long help,max-days:path: \
        -- "$@"
)
eval set -- "$args"
test $# -le 1 && help && exit 1

# 处理脚本参数
while true; do
    case "$1" in
        -h | --help)
            help
            break
            ;;
        -d | --max-days)
            maxDays=$2
            shift 2
            ;;
        -p | --path)
            dataSavingPath=$2
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
