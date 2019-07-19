# 当前文件夹路径
v2ray_base_dir=$(
    cd $(dirname $0)
    pwd -P
)

# 加载环境变量
# source ${v2ray_base_dir}/../env-var.sh

# 加载配置文件
source ${v2ray_base_dir}/../config.sh


# 工具目录
tools_dir=${v2ray_base_dir}/../tools

use_help() {
    cat <<-EOF
用法：  ssh.sh [选项] 命令
选项：
    -a  自动模式
EOF
}

installV2Ray() {
    # 检查依赖
    bash ${tools_dir}/install-tool.sh -m firewall-cmd firewalld

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

    # 将 V2Ray 的端口加入防火墙
    firewall-cmd --zone=public --add-port=${v2ray_port}/tcp --permanent
    firewall-cmd --zone=public --add-port=${v2ray_port}/udp --permanent

    # 重启 firewall
    firewall-cmd --reload

}

# 入口
is_manual=1

if [ -z "$1" ]; then
    use_help
    exit 1
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
