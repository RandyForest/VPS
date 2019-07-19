# 当前文件夹路径
ssr_base_dir=$(dirname $0)

# 加载环境变量
# source ${ssr-base_dir}/../env-var.sh

# 加载配置文件
source ${ssr_base_dir}/.//config.sh


# 工具目录
tools_dir=${ssr_base_dir}/../tools

use_help() {
    cat <<-EOF
用法：  shadowsocksr.sh [选项] 命令
选项：
    -a  自动模式
EOF
}

install(){
    echo "检查依赖..."
    bash ${tools_dir}/install-tool.sh git
    bash ${tools_dir}/install-tool.sh -m firewall-cmd firewalld

    # 获取 Shadowsocksr
    git clone https://github.com/shadowsocksr-backup/shadowsocksr.git

    mv ./shadowsocksr /usr/local/

    # 默认配置
    # 默认 Shadowsocksr 端口
    ssr_port_default=38989

    # 默认 Shadowsocksr 密码
    ssr_pass_default=123456

    # 默认 Shadowsocksr 加密方式
    ssr_method_default=aes-256-cfb

    # 默认 Shadowsocksr OBFS
    ssr_obfs_default=tls1.2_ticket_auth

    if [ ${is_manual} -eq 1 ]; then
        read -p "输入 Shadowsocksr 监听端口（默认：${ssr_port_default}）：" ssr_port
        if [ -z "${ssr_port}" ]; then
            ssr_port=${ssr_port_default}
        fi

        read -p "输入 Shadowsocksr 密码（默认：${ssr_pass_default}）：" ssr_pass
        if [ -z "${ssr_pass}" ]; then
            ssr_pass=${ssr_pass_default}
        fi

        read -p "输入 Shadowsocksr 加密方法（默认：${ssr_method_default}）：" ssr_method
        if [ -z "${ssr_method}" ]; then
            ssr_method=${ssr_method_default}
        fi

        read -p "输入 Shadowsocksr OBFS（默认：${ssr_obfs_default}）：" ssr_obfs
        if [ -z "${ssr_obfs}" ]; then
            ssr_obfs=${ssr_obfs_default}
        fi
    else
        echo "设置默认 Shadowsocksr 监听端口：${ssr_port_default}"
        ssr_port=${ssr_port_default}

        echo "设置默认 Shadowsocksr 密码：${ssr_pass_default}"
        ssr_pass=${ssr_pass_default}

        echo "设置默认 Shadowsocksr 加密方法：${ssr_method_default}"
        ssr_method=${ssr_method_default}

        echo "设置默认 Shadowsocksr OBFS：${ssr_obfs_default}"
        ssr_obfs=${ssr_obfs_default}

    fi

    # 命令行方式启动 Shadowsocksr
    python /usr/local/shadowsocksr/shadowsocks/server.py -p ${ssr_port} -k ${ssr_pass} -m ${ssr_method} -o ${ssr_obfs} -d start

    # 复制 Shadowsocksr 配置文件到 /ect
    # cp -r shadowsocksr /etc

    # 以加载配置文件方式启动
    # python shadowsocksr/shadowsocks/server.py -c /etc/shadowsocksr/config.json -d start

    echo "配置服务..."
    cat >/etc/systemd/system/shadowsocksr.service <<-EOF
[Unit]
Description=Shadowsocksr
After=network.target

[Service]
Type=forking
ExecStart=/bin/python /usr/local/shadowsocksr/shadowsocks/server.py -p ${ssr_port} -k ${ssr_pass} -m ${ssr_method} -o ${ssr_obfs} -d start
ExecStop=/bin/python /usr/local/shadowsocksr/shadowsocks/server.py -d stop

[Install]
WantedBy=multi-user.target
EOF

    # 服务方式启动 Shadowsocksr
    systemctl daemon-reload
    systemctl start shadowsocksr
    systemctl enable shadowsocksr

    # 将 Shadowsocksr 的端口加入防火墙
    firewall-cmd --zone=public --add-port=${ssr_port}/tcp --permanent
    firewall-cmd --zone=public --add-port=${ssr_port}/udp --permanent

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
*) echo "未知命令！" ;;
esac
