#!/usr/bin/sh

# 读取服务器信息
# shellcheck disable=SC2039
# shellcheck disable=SC1090
# shellcheck disable=SC2046
source $(dirname "$0")/../ServerInfo/ServerInfo.sh
source $(dirname "$0")/../ServerInfo/Initialization.sh "$(basename "$0")"

# 目标服务器
user=root
port=port
password=password

# 删除原始记录
ssh-keygen -R "$JUMP_KNOW_HOST"

cat > $(dirname "$0")/../RunTime/"$TARGET" <<EXPECT
    spawn ssh -p $JUMP_SERVER_PORT $JUMP_SERVER_USER@$JUMP_SERVER
    expect {
            "(yes/no)?"
                {send "yes\n"; exp_continue}
            "Password:"
                {send "$JUMP_SERVER_PASSWORD\n"; exp_continue}
            "$JUMP_SERVER_USER"
                {send "ssh -p $port $user@$TARGET\n"; exp_continue}
            "$user@$TARGET's password:"
                {send "$password\n"; exp_continue}
            "~"
                {send "clear\n"}
    }
    expect eof
    interact
EXPECT

# 执行文件
/usr/bin/expect $(dirname "$0")/../RunTime/"$TARGET"