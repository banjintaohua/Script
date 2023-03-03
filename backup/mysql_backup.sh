#!/bin/bash
###
### Filename: mysql_backup.sh
### Author: banjintaohua
### Version: 1.0.0
###
### Description:
###   mysqldump backup tables.
###
### Usage: mysql_backup.sh [options...]
###
### Options:
###   -h, --help         show help message.
###   -d, --max-days     days of data retention, the default is keep 7 days
###   -p, --path         data saving path, the default is /tmp

# 读取配置信息
source "$(dirname "$0")"/config/config.sh
mysqlHost="$MYSQL_HOST"
mysqlPort="$MYSQL_PORT"
mysqlUser="$MYSQL_USER"
mysqlPassword="$MYSQL_PASSWORD"
maxDays=7
dataSavingPath=/tmp/mysql_backup

# 失败立即退出
set -e
set -o pipefail

function help() {
    sed -rn 's/^### ?//p' "$0"
    exit 1
}

function backup() {

    # 解析需要备份的数据库和表
    test $# -ne 2 && echo 'database/tables is required' && exit 1
    database=$1
    IFS=$','
    tables=($2)

    # 按表粒度备份文件
    prefix=$(date -u "+%Y%m%d")
    for table in  ${tables[*]}; do
        mysqldump -h"$mysqlHost" -P"$mysqlPort" -u"$mysqlUser" -p"$mysqlPassword" -R -E "$database" "$table" > "$dataSavingPath"/"$prefix"_"$database"_"$table".sql
    done

    # 打包压缩
    (cd "$dataSavingPath" && tar -cvz -f "$prefix"_"$database".tar.gz ./*.sql)

    # 清理数据
    rm -f "$dataSavingPath"/*.sql
}

function main() {
    # 清理旧数据
    test -d $dataSavingPath || mkdir -p $dataSavingPath
    find "$dataSavingPath" -mtime +"$maxDays" -type f -exec rm -f '{}' \;

    # 备份1
    backup mysql user,slave_master_info

    # 备份2
    backup information_schema VIEWS,TRIGGERS
}

# 解析脚本参数
args=$(
    getopt \
        --option hd::p:: \
        --long help,max-days::--path:: \
        -- "$@"
)
eval set -- "$args"

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
    esac
done

main
