#!/usr/bin/env bash
###
### Filename: cpu_memory_monitor.sh
### Author: banjintaohua
### Version: 1.0.0
###
### Description:
###   monitoring process cpu/memory usage.
###
### Usage: cpu_memory_monitor.sh [options...]
###
### Options:
###   -h, --help             show help message.
###   -p, --process          process name.
###   -i, --interval         refresh interval (seconds).
###   -o, --output           output file.
###   -d, --duration         the running time of the script (seconds).

# 默认配置
PROCESS_NAME=""
REFRESH_INTERVAL=5
OUTPUT_FILE=""
START_TIME=$(date +%s)
MONITOR_DURATION=$((24 * 60 * 60))

# 失败立即退出
set -e
set -o pipefail

# 使用说明
function help() {
    sed -rn 's/^### ?//p' "$0"
    exit 1
}

# 监控指定程序的 CPU/Memory 信息
function main() {
    while true
    do
        # 过滤内核线程，并补充时间信息
        process_metric=$(ps ax -o pid,ppid,%cpu,%mem,cmd | awk -v timestamp="$(date +%s)" '{if($5 ~ /^[^\[]/){print timestamp,$1,$2,$3,$4,substr($0, index($0,$5))}}')

        # 获取指定的进程信息并转为 CSV 格式
        process_metric=$(echo "$process_metric" | grep "$PROCESS_NAME" | awk 'BEGIN { OFS = "," } { print $1, $2, $3,$4,$5,substr($0, index($0,$6))}')

        # 输出指标信息
        [[ -f $OUTPUT_FILE ]] && echo "$process_metric" >> "$OUTPUT_FILE" || echo "$process_metric"
        if (( $(date +%s) - START_TIME >= MONITOR_DURATION )); then
            exit 0
        fi
        sleep $REFRESH_INTERVAL
    done

}

# 解析脚本参数
args=$(
    getopt \
        --options hp:i::o::d:: \
        --longoptions help,process:,interval::,output::,duration:: \
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
        -p | --process)
            PROCESS_NAME=$2
            shift 2
            ;;
        -i | --interval)
            REFRESH_INTERVAL=$2
            shift 2
            ;;
        -o | --output)
            OUTPUT_FILE=$2
            shift 2
            ;;
        -d | --duration)
            MONITOR_DURATION=$2
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

# 检查必填选项
if [ -z "${PROCESS_NAME}" ]; then
  echo "Option '--process' is required." 1>&2
  exit 1
fi

main
