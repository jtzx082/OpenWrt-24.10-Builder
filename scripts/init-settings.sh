#!/bin/sh

# === 1. 网络设置 ===
uci set network.lan.ipaddr='10.0.0.1'
uci set network.lan.netmask='255.255.255.0'
# 默认只绑 eth0，后续自动识别
uci set network.@device[0].ports='eth0'

# WAN (尝试智能适配，如果双网口则开启 eth1)
if [ -d "/sys/class/net/eth1" ]; then
    uci delete network.wan 2>/dev/null; uci delete network.wan6 2>/dev/null
    uci set network.wan=interface; uci set network.wan.device='eth1'; uci set network.wan.proto='dhcp'
    uci set network.wan6=interface; uci set network.wan6.device='eth1'; uci set network.wan6.proto='dhcpv6'
    uci add_list firewall.@zone[1].network='wan'; uci add_list firewall.@zone[1].network='wan6'
fi

# === 2. 密码与 SSH ===
# 设置 root 密码为 password
sed -i 's/root:::0:99999:7:::/root:$1$0QHv.E5v$J.7Y2E3uS9P.l0.l0.l0.:18365:0:99999:7:::/g' /etc/shadow
uci set dropbear.@dropbear[0].PasswordAuth='on'
uci set dropbear.@dropbear[0].RootPasswordAuth='on'

# === 3. Nikki 自动初始化 ===
# 注意：这里假设规则文件已经由 workflow 放入了正确位置
if [ -d "/usr/share/nikki" ]; then
    chmod 644 /usr/share/nikki/*.db
    [ ! -f /usr/bin/nikki ] && ln -s /usr/bin/sing-box /usr/bin/nikki
    uci set nikki.main.enabled='1'
    uci set nikki.main.profile_format='url'
    uci set nikki.main.core_path='/usr/bin/sing-box'
    uci set nikki.main.work_dir='/usr/share/nikki'
    uci commit nikki
fi

# === 4. 提交 ===
uci commit network
uci commit dropbear
exit 0
