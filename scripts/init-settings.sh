#!/bin/sh

# === 1. 语言与界面设置 ===
# 强制设置为简体中文 (OpenWrt 23/24 标准代码 zh_Hans)
uci set luci.main.lang='zh_Hans'
# 强制指定主题，防止界面 Design 为空
uci set luci.main.mediaurlbase='/luci-static/bootstrap'
uci commit luci

# === 2. 网络设置 (PVE/物理机通用) ===

# 修改LAN接口的默认IP地址
uci set network.lan.ipaddr='10.0.0.1'

# 添加eth2和eth3到device配置
uci add_list network.@device[0].ports='eth2'
uci add_list network.@device[0].ports='eth3'

# 设置root密码为password
echo -e "password\npassword" | passwd root

# 应用更改
uci commit network

# === 3. 防火墙修复 (解决有IP但无法上网的核心) ===
# 确保 WAN 口被正确加入 WAN 防火墙区域
uci delete firewall.@zone[1].network 2>/dev/null
uci add_list firewall.@zone[1].network='wan'
uci add_list firewall.@zone[1].network='wan6'

# 开启 NAT 伪装 (Masquerade) 和 流量转发
uci set firewall.@zone[1].masq='1'
uci set firewall.@defaults[0].forward='ACCEPT'
uci set firewall.@defaults[0].input='ACCEPT'
uci set firewall.@defaults[0].output='ACCEPT'

# === 4. Nikki 规则初始化 ===
if [ -d "/usr/share/nikki" ]; then
    chmod -R 755 /usr/share/nikki
    [ ! -f /usr/bin/nikki ] && ln -s /usr/bin/sing-box /usr/bin/nikki
    uci set nikki.main.enabled='1'
    uci set nikki.main.profile_format='url'
    uci set nikki.main.core_path='/usr/bin/sing-box'
    uci set nikki.main.work_dir='/usr/share/nikki'
    uci commit nikki
fi

# === 5. 应用更改 ===
uci commit network
uci commit firewall
uci commit system

# === 6. PVE 网卡性能优化 (防断流) ===
cat > /etc/rc.local <<EOF
ethtool -K eth0 tx off rx off 2>/dev/null
ethtool -K eth1 tx off rx off 2>/dev/null
exit 0
EOF

exit 0
