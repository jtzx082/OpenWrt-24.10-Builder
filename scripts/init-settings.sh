#!/bin/sh

# === 1. 语言与界面设置 ===
# 强制设置为简体中文
uci set luci.main.lang='zh_Hans'
# 强制指定主题
uci set luci.main.mediaurlbase='/luci-static/bootstrap'
uci commit luci

# === 2. 网络设置 (PVE/物理机通用) ===

# 修改LAN接口的默认IP地址
uci set network.lan.ipaddr='10.0.0.1'

# 绑定网口 (修复逻辑：先删除默认列表，再重新添加，防止重复或冲突)
uci delete network.@device[0].ports 2>/dev/null
uci add_list network.@device[0].ports='eth0'
uci add_list network.@device[0].ports='eth2'
uci add_list network.@device[0].ports='eth3'

# 应用网络更改
uci commit network

# === 3. 密码设置 (双重保险) ===
# 如果源码级修改失败，这里会作为备用方案生效
echo -e "password\npassword" | passwd root

# === 4. 防火墙修复 (解决有IP但无法上网的核心) ===
# 确保 WAN 口被正确加入 WAN 防火墙区域
uci delete firewall.@zone[1].network 2>/dev/null
uci add_list firewall.@zone[1].network='wan'
uci add_list firewall.@zone[1].network='wan6'

# 开启 NAT 伪装 (Masquerade) 和 流量转发
uci set firewall.@zone[1].masq='1'
uci set firewall.@defaults[0].forward='ACCEPT'
uci set firewall.@defaults[0].input='ACCEPT'
uci set firewall.@defaults[0].output='ACCEPT'
uci commit firewall

# === 5. Nikki 规则初始化 ===
if [ -d "/usr/share/nikki" ]; then
    chmod -R 755 /usr/share/nikki
    # 增加文件检测，防止软链接已存在报错
    [ ! -f /usr/bin/nikki ] && ln -s /usr/bin/sing-box /usr/bin/nikki
    uci set nikki.main.enabled='1'
    uci set nikki.main.profile_format='url'
    uci set nikki.main.core_path='/usr/bin/sing-box'
    uci set nikki.main.work_dir='/usr/share/nikki'
    uci commit nikki
fi

# === 6. PVE 网卡性能优化 (防断流) ===
# 使用 tee 命令写入，避免权限问题
cat > /etc/rc.local <<EOF
ethtool -K eth0 tx off rx off 2>/dev/null
ethtool -K eth1 tx off rx off 2>/dev/null
exit 0
EOF
chmod +x /etc/rc.local

# === 7. 结束 ===
# 确保脚本返回 0，uci-defaults 才能判定执行成功并自动删除脚本
exit 0
