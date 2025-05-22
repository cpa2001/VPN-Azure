#!/bin/bash

set -e

# 变量定义
USERNAME="username"
PASSWORD="passwd"
HOME_DIR="/home/$USERNAME"
SS_CONFIG="/etc/shadowsocks-libev/config.json"
SS_SERVICE="/lib/systemd/system/shadowsocks-libev.service"
ENCRYPT_METHOD="aes-256-cfb"
SERVER_PORT=460
SERVER_IP="0.0.0.0"

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 权限运行此脚本。"
  exit 1
fi

echo "开始配置 Shadowsocks 服务..."

# 更新系统软件包
echo "更新系统软件包..."
apt update && apt upgrade -y

# 安装必要的软件包
echo "安装必要的软件包..."
apt install -y shadowsocks-libev ufw

# 创建新用户 chenpengan 并设置密码
if id "$USERNAME" &>/dev/null; then
  echo "用户 $USERNAME 已存在，跳过创建用户步骤。"
else
  echo "创建用户 $USERNAME..."
  useradd -m -d "$HOME_DIR" -s /bin/bash "$USERNAME"
  echo "$USERNAME:$PASSWORD" | chpasswd
  usermod -aG sudo "$USERNAME"
  echo "用户 $USERNAME 创建完成并添加到 sudo 组。"
fi

# 配置 Shadowsocks
echo "配置 Shadowsocks..."
cat > "$SS_CONFIG" <<EOL
{
    "server": "$SERVER_IP",
    "server_port": $SERVER_PORT,
    "password": "$PASSWORD",
    "timeout": 300,
    "method": "$ENCRYPT_METHOD",
    "fast_open": false
}
EOL

# 设置配置文件权限
chmod 644 "$SS_CONFIG"

# 检查并修复 Shadowsocks systemd 服务文件
echo "检查 Shadowsocks systemd 服务文件..."
if grep -q "^ExecStart=/usr/bin/ss-server -c \$CONFFILE \$DAEMON_ARGS" "$SS_SERVICE"; then
  echo "Shadowsocks systemd 服务文件配置正确。"
else
  echo "修复 Shadowsocks systemd 服务文件..."
  cat > "$SS_SERVICE" <<EOL
# This file is part of shadowsocks-libev.
#
# Shadowsocks-libev is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This file is default for Debian packaging. See also
# /etc/default/shadowsocks-libev for environment variables.

[Unit]
Description=Shadowsocks-libev Default Server Service
Documentation=man:shadowsocks-libev(8)
After=network-online.target

[Service]
Type=simple
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
DynamicUser=true
EnvironmentFile=/etc/default/shadowsocks-libev
LimitNOFILE=32768
ExecStart=/usr/bin/ss-server -c \$CONFFILE \$DAEMON_ARGS

[Install]
WantedBy=multi-user.target
EOL
fi

# 重新加载 systemd 配置
echo "重新加载 systemd 配置..."
systemctl daemon-reload

# 启用并启动 Shadowsocks 服务
echo "启用并启动 Shadowsocks 服务..."
systemctl enable shadowsocks-libev
systemctl restart shadowsocks-libev

# 检查 Shadowsocks 服务状态
echo "检查 Shadowsocks 服务状态..."
systemctl status shadowsocks-libev --no-pager

# 配置 UFW 防火墙
echo "配置 UFW 防火墙..."
ufw allow OpenSSH
ufw allow "$SERVER_PORT"/tcp
ufw --force enable

echo "防火墙配置完成。"

# 验证 Shadowsocks 是否在监听指定端口
echo "验证 Shadowsocks 是否在监听端口 $SERVER_PORT..."
if ss -tuln | grep -q ":$SERVER_PORT "; then
  echo "Shadowsocks 已在端口 $SERVER_PORT 上监听。"
else
  echo "警告：Shadowsocks 未在端口 $SERVER_PORT 上监听，请检查配置。"
fi

# 输出连接信息
PUBLIC_IP=$(curl -s ifconfig.me)
echo "Shadowsocks 已成功安装并配置。"
echo "可以使用以下信息连接 Shadowsocks 服务："
echo "服务器地址: $PUBLIC_IP"
echo "端口: $SERVER_PORT"
echo "密码: $PASSWORD"
echo "加密方法: $ENCRYPT_METHOD"

echo "配置完成！"
