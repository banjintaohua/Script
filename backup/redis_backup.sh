#!/usr/bin/env bash
###
### Filename: redis_backup.sh
### Author: banjintaohua
### Version: 1.0.0
###
### Description:
###   redis backup keys.
###
### Usage: redis_backup.sh [options...]
###
### Options:
###   -h, --help         show help message.
###   -o, --output-file  dump all key-value pairs to file
###   -i, --input-file   load all key-value pairs to redis
###   -k, --key          redis key name
###   -m, --mode         load mode, default is dump mode

# 读取配置信息
source "$(dirname "$0")"/config/config.sh
PREFIX=$(date -u "+%Y%m%d")
TMP_FILE="/tmp/$PREFIX-redis-keys.txt"
OUTPUT_FILE="/tmp/$PREFIX-redis-key-value-pairs.txt"
INPUT_FILE=$OUTPUT_FILE
REDIS_KEY_NAME="foobar"
MODE="dump"

# 失败立即退出
set -e
set -o pipefail

function help() {
    sed -rn 's/^### ?//p' "$0"
    exit 1
}

function dump() {
    redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" -n 0 keys "$REDIS_KEY_NAME" > "$TMP_FILE"
    while read -r key
    do
        value=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" -n 0 get "$key")
        echo "$key++$value" >> "$OUTPUT_FILE"
    done < "$TMP_FILE"
}

function load() {
    IFS="++"
    while read -r line
    do
        arr=($line)
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" -n 0 set "${arr[0]}" "${arr[2]}"
    done < "$INPUT_FILE"
}

function main() {
    if [ $MODE == "dump" ]; then
        dump
    fi

    if [ $MODE == "load" ]; then
        load
    fi
}

# 解析脚本参数
args=$(
    getopt \
        --options ho:i:k:m:: \
        --longoptions help,output-file:,input-file:,key:,mode:: \
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
        -o | --output-file)
            test "$MODE" != "dump" && echo 'not dump MODE' && exit
            OUTPUT_FILE=$2
            shift 2
            ;;
        -i | --input-file)
            test "$MODE" != "load" && echo 'not load MODE' && exit
            INPUT_FILE=$2
            shift 2
            ;;
        -k | --key)
            test "$MODE" != "dump" && echo 'not dump MODE' && exit
            REDIS_KEY_NAME=$2
            shift 2
            ;;
        -m | --mode)
            case "$2" in
                "")
                  MODE="dump"
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
