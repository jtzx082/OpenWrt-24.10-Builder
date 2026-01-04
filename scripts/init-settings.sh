#!/bin/sh

# === 1. 语言与界面设置 (强制默认中文) ===
uci set luci.main.lang='zh_cn'
uci commit luci

# === 2. 密码设置 (强制修改为 password) ===
sed -i 's|^root:[^:]* :|root:$1$0QHv.E5v$J.7Y2E3uS9P.l0.l0.l0.:|g' /etc/shadow
uci set dropbear.@dropbear[0].PasswordAuth='on'
uci set dropbear.@dropbear[0].RootPasswordAuth='on'
uci commit dropbear

# === 3. 网络设置 (物理机/虚拟机通用适配) ===
# 默认 LAN IP
uci set network.lan.proto='static'
uci set network.lan.ipaddr='10.0.0.1'
uci set network.lan.netmask='255.255.255.0'

# 强制绑定 eth0 到 LAN
uci set network.lan.device='eth0'
# 尝试将物理机常见的其他网口也绑入 LAN (作为交换机使用)
uci set network.lan.ports='eth0 eth2 eth3 eth4'

# 配置 WAN 口 (如果有 eth1)
uci delete network.wan 2>/dev/null
uci delete network.wan6 2>/dev/null
uci set network.wan=interface
uci set network.wan.device='eth1'
uci set network.wan.proto='dhcp'
uci set network.wan6=interface
uci set network.wan6.device='eth1'
uci set network.wan6.proto='dhcpv6'

# 防火墙区域修正
uci add_list firewall.@zone[1].network='wan'
uci add_list firewall.@zone[1].network='wan6'
uci set firewall.@defaults[0].forward='ACCEPT'

# === 4. Nikki 规则初始化 (自动加载内置规则) ===
if [ -d "/usr/share/nikki" ]; then
    chmod 644 /usr/share/nikki/*.db
    [ ! -f /usr/bin/nikki ] && ln -s /usr/bin/sing-box /usr/bin/nikki
    uci set nikki.main.enabled='1'
    uci set nikki.main.profile_format='url'
    uci set nikki.main.core_path='/usr/bin/sing-box'
    uci set nikki.main.work_dir='/usr/share/nikki'
    uci commit nikki
fi

# === 5. 提交配置 ===
uci commit network
uci commit firewall

# === 6. 网卡防断流优化 (写入 rc.local) ===
# 解决部分虚拟网卡校验和错误问题
cat >> /etc/rc.local <<EOF
ethtool -K eth0 tx off rx off 2>/dev/null
ethtool -K eth1 tx off rx off 2>/dev/null
exit 0
EOF

exit 0
