#!/bin/sh

# === PVE/虚拟化专用优化 ===
# 修复 VirtIO 网卡可能导致的断流或无法联网问题
sed -i '/exit 0/d' /etc/rc.local
cat <<EOF >> /etc/rc.local
ethtool -K eth0 tx off rx off 2>/dev/null
ethtool -K eth1 tx off rx off 2>/dev/null
exit 0
EOF

# === 首次启动标记 ===
# 标记设置已完成，防止 OpenWrt 反复重置配置
touch /etc/config/network
uci commit network

exit 0
