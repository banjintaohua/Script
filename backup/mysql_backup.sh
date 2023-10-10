#!/usr/bin/env bash
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
###   -p, --path         data saving path, the default is /tmp/mysql_backup

# 读取配置信息
source "$(dirname "$0")"/config/config.sh
MAX_DAYS=7
DATA_SAVING_PATH=/tmp/mysql_backup

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
        mysqldump -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" \
            --single-transaction --quick \
            -R -E "$database" "$table" > "$DATA_SAVING_PATH"/"$prefix"_"$database"_"$table".sql
    done

    # 打包压缩
    (cd "$DATA_SAVING_PATH" && tar -cvz -f "$prefix"_"$database".tar.gz ./*.sql)

    # 清理数据
    rm -f "$DATA_SAVING_PATH"/*.sql
}

function main() {
    # 清理旧数据
    test -d $DATA_SAVING_PATH || mkdir -p $DATA_SAVING_PATH
    find "$DATA_SAVING_PATH" -mtime +"$MAX_DAYS" -type f -exec rm -f '{}' \;

    # 备份1
    backup mysql user,slave_master_info

    # 备份2
    backup information_schema VIEWS,TRIGGERS
}

# 解析脚本参数
args=$(
    getopt \
        --options hd:p: \
        --longoptions help,max-days:,path: \
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
