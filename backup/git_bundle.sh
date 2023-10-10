#!/usr/bin/env bash
###
### Filename: git_bundle.sh
### Author: banjintaohua
### Version: 1.0.0
###
### Description:
###   dump or load git commits.
###
### Usage: git_bundle.sh [options...]
###
### Options:
###   -h, --help      show help message.
###   -f, --file      file path of git bundle, the default is /tmp/bundles/commits.bundle.
###   -l, --load      load git commits from bundle file.
###   -d, --dump      dump git commits as bundle file.
###   -b, --base      base branch, the default is master
###   -t, --target    target branch, the default branch is origin/develop.

# 设置默认值
mkdir -p /tmp/bundles
BUNDLE_FILE="/tmp/bundles/commits.bundle"
MODE='dump'
BASE_BRANCH='HEAD'
TARGET_BRANCH='origin/develop'

# Mac 系统需要加载配置文件，加载别名
if [[ -f ~/.bash_profile && "$(uname)" == "Darwin" ]]; then
    shopt -s expand_aliases
    . ~/.bash_profile
fi

# 失败立即退出
set -e
set -o pipefail

# 使用说明
function help() {
    sed -rn 's/^### ?//p' "$0"
    exit 1
}

function dump_git_commits() {
    # 检查当前目录下是否有 git
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "Current directory is not inside a Git repository."
        exit 1
    fi

    # 检查本地分支是否存在
    if [[ "$BASE_BRANCH" != "HEAD" ]]; then
        if ! git show-ref --verify --quiet refs/heads/$BASE_BRANCH; then
            echo "Branch: $BASE_BRANCH does not exist"
            exit 1
        fi
    fi

    # Mac 系统表示导出本机新提交的 commits，所以要检查本地分支是否存在
    if [[ "$(uname)" == "Darwin" && "$TARGET_BRANCH" != "HEAD" ]]; then
        if ! git show-ref --verify --quiet refs/heads/$TARGET_BRANCH; then
            echo "Branch: $TARGET_BRANCH does not exist"
            exit 1
        fi
    fi

    # Linux 系统表示导出远端仓库新提交的 commits，所以要检查远程分支是否存在
    if [[ "$(uname)" == "Linux" ]]; then
        git fetch -p
        if ! git show-ref --verify --quiet refs/remotes/$TARGET_BRANCH; then
            echo "Remote branch: $TARGET_BRANCH does not exist"
            exit 1
        fi
    fi

    # 创建 bundle 文件（只打包在 $TARGET_BRANCH 分支且不在 $BASE_BRANCH 分支的 commit）
    echo "Dumping commits that is in the $TARGET_BRANCH and not in the $BASE_BRANCH"
    echo ""
    git bundle create "$BUNDLE_FILE" "$TARGET_BRANCH" ^"$BASE_BRANCH"
    echo ""
    echo "Dump git bundle successful"
    echo ""
    git bundle verify "$BUNDLE_FILE"

    # 如果是 Mac 系统则打开 bundle 文件所在目录
    if [[ "$(uname)" == "Darwin" ]]; then
        open "$(dirname $BUNDLE_FILE)"
    fi

    # 删除 bundle 文件
    echo "After 180 seconds, the $BUNDLE_FILE will be automatically deleted"
    echo ""
    (
        sleep 180
        rm -f $BUNDLE_FILE &
        echo "Bundle file deleted"
    ) &
}

function load_git_commits() {
    # 检查当前目录下是否有 git
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "Current directory is not inside a Git repository."
        exit 1
    fi

    # 校验 bundle 文件是否合法
    if ! git bundle verify "$BUNDLE_FILE"; then
        echo "The bundle file $BUNDLE_FILE is not valid."
        exit 1
    fi

    # 获取 bundle 文件中的首个分支
    bundle_ref_branch=$(git bundle list-heads "$BUNDLE_FILE" | head -n 1 | awk '{print $NF}')

    # 拉取 bundle 中的 commits 到本地 $TARGET_BRANCH 分支中
    if ! git fetch "$BUNDLE_FILE" "$bundle_ref_branch:$TARGET_BRANCH"; then
        echo "Failed to fetch bundle file: $BUNDLE_FILE"
        exit 1
    fi

    # 如果操作系统是 Linux ，则将 $TARGET_BRANCH 的内容推送到远端仓库
    if [[ "$(uname)" == "Linux" ]]; then
        echo ""
        git push origin $TARGET_BRANCH:$TARGET_BRANCH
        git branch -D $TARGET_BRANCH
    fi

    # 删除 bundle 文件
    echo ""
    echo "Load git bundle successful"
    rm -f $BUNDLE_FILE
}

# 解析脚本参数
args=$(
    getopt \
        --options hf:ldb:t: \
        --longoptions help,file:,load,dump,base:,target: \
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
        -f | --file)
            test -n "$2" && BUNDLE_FILE=$2
            shift 2
            ;;
        -l | --load)
            MODE="load"
            shift 1
            ;;
        -d | --dump)
            MODE="dump"
            shift 1
            ;;
        -b | --base)
            test -n "$2" && BASE_BRANCH=$2
            shift 2
            ;;
        -t | --target)
            test -n "$2" && TARGET_BRANCH=$2
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

if [[ $MODE == "dump" ]]; then
    dump_git_commits
fi

if [[ $MODE == "load" ]]; then
    load_git_commits
fi
