# 用法：    v2ray-install.sh [选项] 命令

echo "# V2Ray 安装脚本 #"

use_help() {
    cat <<-EOF
用法：  ssh.sh [选项] 命令
选项：
    -a  自动模式
EOF
}

install() {
    # 检查依赖
    bash install-tool.sh -m firewall-cmd firewalld

    # /usr/bin/v2ray/v2ray：V2Ray 程序；
    # /usr/bin/v2ray/v2ctl：V2Ray 工具；
    # /etc/v2ray/config.json：配置文件；
    # /usr/bin/v2ray/geoip.dat：IP 数据文件
    # /usr/bin/v2ray/geosite.dat：域名数据文件
    # /etc/systemd/system/v2ray.service: Systemd
    # /etc/init.d/v2ray: SysV
    bash <(curl https://install.direct/go.sh) | tee /tmp/v2ray_install.log

    port_tmp=$(grep -o "PORT:[0-9]\+" /tmp/v2ray_install.log | grep -o "[0-9]\+")

    # 默认配置
    v2ray_port_default=58989
    v2ray_uuid_default=67ff0138-4873-4b0c-912d-a8649b24ecaa

    if [ ${is_manual} -eq 1 ]; then
        read -p "输入V2Ray端口（默认：${v2ray_port_default}）：" v2ray_port
        if [ -z "${v2ray_port}" ]; then
            v2ray_port=${v2ray_port_default}
        fi

        read -p "输入V2Ray UUID（默认：${v2ray_uuid_default}）：" v2ray_uuid
        if [ -z "${v2ray_uuid}" ]; then
            v2ray_uuid=${v2ray_uuid_default}
        fi
    else
        echo "设置默认V2Ray端口：${v2ray_port_default}"
        v2ray_port=${v2ray_port_default}

        echo "设置默认V2Ray UUID：${v2ray_uuid_default}"
        v2ray_uuid=${v2ray_uuid_default}
    fi

    # 修改端口
    sed -i "s/\"port\":${port_tmp}.*/\"port\":${v2ray_port}/" /etc/v2ray/config.json

    # 修改UUID
    sed -i "s/\"id\":.*/\"id\":${v2ray_uuid}/" /etc/v2ray/config.json

    # 运行 V2Ray
    systemctl daemon-reload
    systemctl start v2ray.service
    systemctl enable v2ray.service

    # 为 V2Ray 开启防火墙
    # Create new chain
    # iptables -t nat -N V2RAY
    # iptables -t mangle -N V2RAY
    # iptables -t mangle -N V2RAY_MARK

    # Ignore your V2Ray server's addresses
    # It's very IMPORTANT, just be careful.
    # iptables -t nat -A V2RAY -d 107.175.69.194 -j RETURN

    # Ignore LANs and any other addresses you'd like to bypass the proxy
    # See Wikipedia and RFC5735 for full list of reserved networks.
    # iptables -t nat -A V2RAY -d 0.0.0.0/8 -j RETURN
    # iptables -t nat -A V2RAY -d 10.0.0.0/8 -j RETURN
    # iptables -t nat -A V2RAY -d 127.0.0.0/8 -j RETURN
    # iptables -t nat -A V2RAY -d 169.254.0.0/16 -j RETURN
    # iptables -t nat -A V2RAY -d 172.16.0.0/12 -j RETURN
    # iptables -t nat -A V2RAY -d 192.168.0.0/16 -j RETURN
    # iptables -t nat -A V2RAY -d 224.0.0.0/4 -j RETURN
    # iptables -t nat -A V2RAY -d 240.0.0.0/4 -j RETURN
    # iptables -t nat -A V2RAY -d 117.150.3.134 -j RETURN

    # Anything else should be redirected to Dokodemo-door's local port
    # iptables -t nat -A V2RAY -p tcp -j REDIRECT --to-ports 8080

    # Add any UDP rules
    # ip route add local default dev lo table 100
    # ip rule add fwmark 1 lookup 100
    # iptables -t mangle -A V2RAY -p udp --dport 53 -j TPROXY --on-port 12345 --tproxy-mark 0x01/0x01
    # iptables -t mangle -A V2RAY_MARK -p udp --dport 53 -j MARK --set-mark 1

    # Apply the rules
    # iptables -t nat -A OUTPUT -p tcp -j V2RAY
    # iptables -t mangle -A PREROUTING -j V2RAY
    # iptables -t mangle -A OUTPUT -j V2RAY_MARK

    # 将 V2Ray 的端口加入防火墙
    firewall-cmd --zone=public --add-port=${v2ray_port}/tcp --permanent
    firewall-cmd --zone=public --add-port=${v2ray_port}/udp --permanent

    # 重启 firewall
    firewall-cmd --reload

}

# 入口
is_manual=1

if [ -z "${cmd}" ]; then
    use_help
fi

while [ -n "$1" ]; do
    case "$1" in
    -a)
        is_manual=0
        cmd=$2
        shift
        ;;
    *)
        cmd=$1
        ;;
    esac
    shift
done

case "${cmd}" in
install) install ;;
*) ehco "未知命令！" ;;
esac
