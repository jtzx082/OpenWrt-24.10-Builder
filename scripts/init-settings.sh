#!/bin/sh

# === 网络设置 ===
uci set network.lan.proto='static'
uci set network.lan.ipaddr='10.0.0.1'
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.device='eth0'
uci set network.lan.ports='eth0 eth2 eth3 eth4'

uci delete network.wan 2>/dev/null
uci delete network.wan6 2>/dev/null
uci set network.wan=interface
uci set network.wan.device='eth1'
uci set network.wan.proto='dhcp'

uci set network.wan6=interface
uci set network.wan6.device='eth1'
uci set network.wan6.proto='dhcpv6'

# === 防火墙修复 ===
uci delete firewall.@zone[1].network 2>/dev/null
uci add_list firewall.@zone[1].network='wan'
uci add_list firewall.@zone[1].network='wan6'
uci set firewall.@defaults[0].forward='ACCEPT'
uci set firewall.@defaults[0].input='ACCEPT'
uci set firewall.@defaults[0].output='ACCEPT'

uci commit network
uci commit firewall

# === PVE 优化 ===
cat > /etc/rc.local <<EOF
ethtool -K eth0 tx off rx off 2>/dev/null
ethtool -K eth1 tx off rx off 2>/dev/null
exit 0
EOF

exit 0
