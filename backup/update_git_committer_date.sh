#!/usr/bin/env bash
###
### Filename: update_git_committer_date.sh
### Author: banjintaohua
### Version: 1.0.0
###
### Description:
###   update GIT_COMMITTER_DATE to now date.
###
### Usage: update_git_committer_date.sh [options...]
###
### Options:
###   -h, --help         show help message.
###   -n, --number       number of commits to modify

# 读取配置信息
source "$(dirname "$0")"/config/config.sh
TOP_N_COMMIT=0

# 失败立即退出
# set -x
set -e
set -o pipefail

function help() {
    sed -rn 's/^### ?//p' "$0"
    exit 1
}

function main() {
    # 检查当前目录下是否有 git
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "Current directory is not inside a Git repository."
        exit 1
    fi

    # Amend the first N commits with the new author date and committer date
    for ((i=0; i<$TOP_N_COMMIT; i++)); do
        commit_sha=$(git log -n 1 --skip=$i --pretty=format:"%H")
        old_datetime=$(git log -n 1 --skip=$i --pretty=format:"%ai")
        new_datetime="$(date +%Y-%m-%d) ${old_datetime#* }"

        git filter-branch -f --env-filter "if [ \$GIT_COMMIT == '$commit_sha' ]; then export GIT_AUTHOR_DATE=\"$new_datetime\"; export GIT_COMMITTER_DATE=\"$new_datetime\"; fi" HEAD~$((i+1))..HEAD~$i HEAD

        echo "Commit $commit date updated to $new_datetime"
    done
}

# 解析脚本参数
args=$(
    getopt \
        --options hn: \
        --longoptions help,number: \
        -- "$@"
)
eval set -- "${args}"
test $# -le 1 && help && exit 1

# 处理脚本参数
while true; do
    echo $1
    case "$1" in
        -h | --help)
            help
            break
            ;;
        -n | --number)
            TOP_N_COMMIT=$2
            if [[ $TOP_N_COMMIT =~ ^[0-9]+$ ]]; then
                # 检查变量是否大于0且小于10
                if (( TOP_N_COMMIT < 1 && TOP_N_COMMIT > 10 )); then
                    echo "number must be greater than 0 and less than 10" && exit
                fi
            else
                echo "invalid number" && exit
            fi
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
