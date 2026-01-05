#!/bin/sh

# === 1. Nikki 规则初始化 ===
if [ -d "/usr/share/nikki" ]; then
    chmod -R 755 /usr/share/nikki
    [ ! -f /usr/bin/nikki ] && ln -s /usr/bin/sing-box /usr/bin/nikki
    uci set nikki.main.enabled='1'
    uci set nikki.main.profile_format='url'
    uci set nikki.main.core_path='/usr/bin/sing-box'
    uci set nikki.main.work_dir='/usr/share/nikki'
    uci commit nikki
fi

# === 2. PVE 虚拟网卡性能修复 ===
# 防止 virtio 网卡校验和错误导致断网
cat > /etc/rc.local <<EOF
ethtool -K eth0 tx off rx off 2>/dev/null
ethtool -K eth1 tx off rx off 2>/dev/null
exit 0
EOF

exit 0
