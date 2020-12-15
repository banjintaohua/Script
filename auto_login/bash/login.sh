#!/usr/bin/bash

# 读取配置文件
source /path/to/config

echo "**************************"
echo "① $One"
echo "② $Two"
echo "③ $Three"
echo "④ $Four"
echo "⑤ $Five"
echo "⑥ $Six"
echo "⑦ $Seven"
echo "⑧ $Eight"
echo "⑨ $Nine"
echo "⑩ $Ten"
echo "⑪ $Eleven"
echo "⑫ $Twelve"
echo "⑬ $Thirteen"
echo "⑭ $Fourteen"
echo "⑮ $Fifteen"
echo "⑯ $Sixteen"
echo "⑰ $Seventeen"
echo "⑱ $Eighteen"
echo "⑲ $Nineteen"
echo "**************************"

read -p "请选择需要登录的服务器 :" SERVER

if [[ $SERVER =~ [^0-9]+ ]]; then
    echo "********************************************"
    echo "请选择正确范围的服务器"
    echo "********************************************"
    exit 1
fi

# 提示连接的服务器
echo "您选择的服务器为 : $SERVER"
echo "********************************************"

# 连接服务器
spawn /usr/bin/bash "/path/to/folder/$SERVER.sh"
expect eof
interact