#!/bin/bash
###
### Filename: update_certificate.sh
### Author: banjintaohua
### Version: 1.0.0
###
### Description:
###   Update letsencrypt certificate.
###   If the certificate will expire in 7 days, then automatically renew the certificate and export the certificate file to a specified directory.
###
### Usage: update_certificate.sh [options...]
###
### Options:
###   -d, --domain      domain.
###   -o, --output      certificate output path.
###   -h, --help        show help message.
###
### Example: update_certificate.sh --domain=*.foo.bar

# 读取配置信息
outputPath='./'
domain=

# 失败立即退出
set -e
set -o pipefail

# 使用说明
function help() {
    sed -rn 's/^### ?//p' "$0"
    exit 1
}

function main() {
    containerId=$(docker ps --format "{{.ID}} {{.Names}}" | grep acme | awk '{print $1}')
    if [ -z "$containerId" ]; then
        echo "Container not exist"
        exit 1
    fi

    certificate=/acme.sh/"$domain"_ecc/"$domain".cer
    if ! docker exec "$containerId" test -f "$certificate"; then
        echo "certificate not exist"
        exit 1
    fi

    # 检测证书是否在 604800 秒（7 天）内过期
    if docker exec "$containerId" openssl x509 -checkend 604800 -noout -in "$certificate"; then
        echo "Certificate is good for another day!"
        exit 0
    fi

    echo "Certificate has expired or will do so within 7 days"
    echo "(or is invalid/not found)"

    # 更新证书
    docker exec "$containerId" /root/.acme.sh/acme.sh --renew --insecure --force --ecc -d "${domain}"

    # 删除旧证书
    docker exec "$containerId" mkdir -p "/acme.sh/${domain}_ecc/backup"
    docker exec "$containerId" rm -f /acme.sh/"${domain}"_ecc/backup/*
    echo "Old certificate has been deleted"
    docker exec "$containerId" ls -al /acme.sh/"${domain}"_ecc/backup

    # 重新安装证书
    echo "reinstall certificate"
    docker exec "$containerId" /root/.acme.sh/acme.sh --installcert --ecc -d "$domain" \
      --fullchain-file /acme.sh/"${domain}"_ecc/backup/wildcard-certificate.crt \
      --key-file /acme.sh/"${domain}"_ecc/backup/wildcard-certificate.key

    # 导出配置文件
    docker cp "$containerId":/acme.sh/"${domain}"_ecc/backup/wildcard-certificate.crt "$outputPath"
    docker cp "$containerId":/acme.sh/"${domain}"_ecc/backup/wildcard-certificate.key "$outputPath"
    # docker exec nginx nginx -s reload
}

# 解析脚本参数
args=$(
    getopt \
        --option hd:o:: \
        --long help,domain:,output:: \
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
        -d | --domain)
            domain=$2
            shift 2
            ;;
        -o | --output)
            outputPath=$2
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
if [ -z "${domain}" ]; then
  echo "Option '--domain' is required." 1>&2
  exit 1
fi

main