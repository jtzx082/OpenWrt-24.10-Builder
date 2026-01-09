#!/bin/sh

# === 1. 语言与界面设置 ===
uci set luci.main.lang='zh_Hans'
uci set luci.main.mediaurlbase='/luci-static/bootstrap'
uci commit luci

# === 注意：网络和密码设置已在 build.yml 中通过源码/文件修改完成 ===
# 此处不需要再写 network 和 passwd 相关的命令

# === 2. 防火墙辅助设置 ===
# 确保 WAN 口被正确加入 WAN 防火墙区域（双重保险）
uci delete firewall.@zone[1].network 2>/dev/null
uci add_list firewall.@zone[1].network='wan'
uci add_list firewall.@zone[1].network='wan6'
uci set firewall.@zone[1].masq='1'
uci set firewall.@defaults[0].forward='ACCEPT'
uci set firewall.@defaults[0].input='ACCEPT'
uci set firewall.@defaults[0].output='ACCEPT'
uci commit firewall

# === 3. Nikki 规则初始化 ===
if [ -d "/usr/share/nikki" ]; then
    chmod -R 755 /usr/share/nikki
    [ ! -f /usr/bin/nikki ] && ln -s /usr/bin/sing-box /usr/bin/nikki
    uci set nikki.main.enabled='1'
    uci set nikki.main.profile_format='url'
    uci set nikki.main.core_path='/usr/bin/sing-box'
    uci set nikki.main.work_dir='/usr/share/nikki'
    uci commit nikki
fi

# === 4. PVE 网卡性能优化 (防断流) ===
cat > /etc/rc.local <<EOF
ethtool -K eth0 tx off rx off 2>/dev/null
ethtool -K eth1 tx off rx off 2>/dev/null
exit 0
EOF
chmod +x /etc/rc.local

exit 0
