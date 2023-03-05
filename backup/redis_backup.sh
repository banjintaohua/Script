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
redisHost="$REDIS_HOST"
redisPort="$REDIS_PORT"
redisPassword="$REDIS_PASSWORD"
prefix=$(date -u "+%Y%m%d")
tmpFile=/tmp/"$prefix-redis-keys.txt"
outputFile="/tmp/$prefix-redis-key-value-pairs.txt"
inputFile=$outputFile
redisKeyName="foobar"
mode="dump"

# 失败立即退出
set -e
set -o pipefail

function help() {
    sed -rn 's/^### ?//p' "$0"
    exit 1
}

function dump() {
    redis-cli -h "$redisHost" -p "$redisPort" -a "$redisPassword" -n 0 keys "$redisKeyName" > "$tmpFile"
    while read -r key
    do
        value=$(redis-cli -h "$redisHost" -p "$redisPort" -a "$redisPassword" -n 0 get "$key")
        echo "$key++$value" >> "$outputFile"
    done < "$tmpFile"
}

function load() {
    IFS="++"
    while read -r line
    do
        arr=($line)
        redis-cli -h "$redisHost" -p "$redisPort" -a "$redisPassword" -n 0 set "${arr[0]}" "${arr[2]}"
    done < "$inputFile"
}

function main() {
    if [ $mode == "dump" ]; then
        dump
    fi

    if [ $mode == "load" ]; then
        load
    fi
}

# 解析脚本参数
args=$(
    getopt \
        --option ho:i:k:m:: \
        --long help,output-file:,input-file:,key:,mode:: \
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
        -o | --output-file)
            test "$mode" != "dump" && echo 'not dump mode' && exit
            outputFile=$2
            shift 2
            ;;
        -i | --input-file)
            test "$mode" != "load" && echo 'not load mode' && exit
            inputFile=$2
            shift 2
            ;;
        -k | --key)
            test "$mode" != "dump" && echo 'not dump mode' && exit
            redisKeyName=$2
            shift 2
            ;;
        -m | --mode)
            case "$2" in
                "")
                  mode="dump"
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
