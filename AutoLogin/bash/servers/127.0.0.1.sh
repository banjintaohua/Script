#!/usr/bin/bash

# 目标服务器
USER=root
PORT=port
PASSWORD=password

# 读取服务器信息
source "$(dirname "$0")"/../config/config.sh

# 获取 IP 地址(文件名被命名为了服务器 IP)
if ! [[ $(basename "$0") =~ ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.sh$ ]]; then
    echo "解析文件名失败, 文件名: $0 需为 IP 地址"
    exit 1
else
    SERVER=$(basename "$0" | grep -oE '^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}')
fi

# 删除原始记录
if [[  $(grep -c "[$SERVER]:$PORT" < ~/.ssh/known_hosts) -ge 1 ]]; then
    ssh-keygen -R "[$SERVER]:$PORT"
fi

# 删除原始记录
ssh-keygen -R "[$JUMP_SERVER]:$JUMP_SERVER_PORT"

cat > "$(dirname "$0")/runtime/$SERVER" <<EXPECT
    spawn ssh -p $JUMP_SERVER_PORT $JUMP_SERVER_USER@$JUMP_SERVER

    expect {
         "(yes/no)?"
             {send "yes\n"; exp_continue}
         "Password:"
             {send "$JUMP_SERVER_PASSWORD\n"; exp_continue}
         "$JUMP_SERVER_USER"
             {send "ssh -p $PORT $USER@$SERVER\n"; exp_continue}
         "$USER@$SERVER's password:"
             {send "$PASSWORD\n"; exp_continue}
         "~"
             {send "clear\n"}
    }
    expect eof

    interact
EXPECT

# 执行文件
/usr/bin/expect "$(dirname "$0")/runtime/$SERVER"
