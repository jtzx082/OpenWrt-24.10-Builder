#!/bin/sh

# === 1. PVE/虚拟化专用优化 ===
# 修复 VirtIO 网卡可能导致的断流或无法联网问题
sed -i '/exit 0/d' /etc/rc.local
cat <<EOF >> /etc/rc.local
ethtool -K eth0 tx off rx off 2>/dev/null
ethtool -K eth1 tx off rx off 2>/dev/null
exit 0
EOF

exit 0
