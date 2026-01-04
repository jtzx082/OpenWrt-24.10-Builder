#!/bin/sh

# === 1. 语言设置 (核心修复：强制设置为 zh_Hans) ===
# 注意：OpenWrt 23/24 使用 zh_Hans 而非 zh_cn
uci set luci.main.lang='zh_Hans'
# 预先设置语言包偏好
uci set luci.languages.zh_Hans='Chinese (Simplified)'
uci commit luci

# === 2. 密码设置 (核心修复：使用 chpasswd) ===
# 这种方式比 sed 修改 shadow 文件更稳定
echo "root:password" | chpasswd
# 允许 SSH 密码登录
uci set dropbear.@dropbear[0].PasswordAuth='on'
uci set dropbear.@dropbear[0].RootPasswordAuth='on'
uci commit dropbear

# === 3. 网络设置 (PVE/物理机通用) ===
# 设置 LAN
uci set network.lan.proto='static'
uci set network.lan.ipaddr='10.0.0.1'
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.device='eth0'
# 桥接更多网口 (如果存在)
uci set network.lan.ports='eth0 eth2 eth3 eth4'

# 设置 WAN (重建逻辑)
uci delete network.wan 2>/dev/null
uci delete network.wan6 2>/dev/null

uci set network.wan=interface
uci set network.wan.device='eth1'
uci set network.wan.proto='dhcp'

uci set network.wan6=interface
uci set network.wan6.device='eth1'
uci set network.wan6.proto='dhcpv6'

# === 4. 防火墙修复 (解决 PVE 有 IP 没网的问题) ===
# 确保 WAN 接口被正确加入 wan 区域
uci delete firewall.@zone[1].network 2>/dev/null
uci add_list firewall.@zone[1].network='wan'
uci add_list firewall.@zone[1].network='wan6'

# 开启转发 (解决 Docker/虚拟机环境下的 NAT 问题)
uci set firewall.@defaults[0].forward='ACCEPT'
uci set firewall.@defaults[0].input='ACCEPT'
uci set firewall.@defaults[0].output='ACCEPT'

# === 5. Nikki 规则初始化 ===
if [ -d "/usr/share/nikki" ]; then
    chmod -R 755 /usr/share/nikki
    [ ! -f /usr/bin/nikki ] && ln -s /usr/bin/sing-box /usr/bin/nikki
    uci set nikki.main.enabled='1'
    uci set nikki.main.profile_format='url'
    uci set nikki.main.core_path='/usr/bin/sing-box'
    uci set nikki.main.work_dir='/usr/share/nikki'
    uci commit nikki
fi

# === 6. 应用更改 ===
uci commit network
uci commit firewall
uci commit system

# === 7. PVE 虚拟网卡性能修复 ===
# 防止 virtio 网卡校验和错误导致断网
cat > /etc/rc.local <<EOF
ethtool -K eth0 tx off rx off 2>/dev/null
ethtool -K eth1 tx off rx off 2>/dev/null
exit 0
EOF

exit 0
