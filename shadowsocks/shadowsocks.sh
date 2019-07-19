# 当前文件夹路径
ss_base_dir=$(
    cd $(dirname $0)
    pwd -P
)

# 加载环境变量
# source ${ss_base_dir}/../env-var.sh

# 加载配置文件
source ${ss_base_dir}/../config.sh

# 工具目录
tools_dir=${ss_base_dir}/../tools

use_help() {
    cat <<-EOF
用法：  shadowsocks.sh [选项] 命令
选项：
    -a  自动模式
EOF
}

install() {
    # 读取默认配置
    # 默认 Shadowsocks 监听端口
    # ss_port_default=$(bash load-config.sh -a "ss_port")

    # 默认 Shadowsocks 密码
    # ss_pass_default=$(bash load-config.sh -a "ss_pass")

    # 默认 Shadowsocks 加密方法
    # ss_method_default=$(bash load-config.sh -a "ss_method")

    if [ ${is_manual} -eq 1 ]; then
        read -p "输入 Shadowsocks 监听端口（默认：${ss_port_default}）：" ss_port
        if [ -z "${ss_port}" ]; then
            ss_port=${ss_port_default}
        fi

        read -p "输入 Shadowsocks 密码（默认：${ss_pass_default}）：" ss_pass
        if [ -z "${ss_pass}" ]; then
            ss_pass=${ss_pass_default}
        fi

        read -p "输入 Shadowsocks 加密方法（默认：${ss_method_default}）：" ss_method
        if [ -z "${ss_method}" ]; then
            ss_method=${ss_method_default}
        fi
    else
        echo "设置默认 Shadowsocks 监听端口：${ss_port_default}"
        ss_port=${ss_port_default}

        echo "设置默认 Shadowsocks 密码：${ss_pass_default}"
        ss_pass=${ss_pass_default}

        echo "设置默认 Shadowsocks 加密方法：${ss_method_default}"
        ss_method=${ss_method_default}
    fi

    echo "检查依赖..."
    bash ${tools_dir}/install-tool.sh -m pip python-pip
    bash ${tools_dir}/install-tool.sh -m firewall-cmd firewalld

    # 更新 pip
    pip install --upgrade pip

    # 安装 Shadowsocks
    pip install shadowsocks

    # 命令行方式启动 Shadowsocks
    # ssserver -s 0.0.0.0 -p ${ss_port} -k ${ss_pass} -m ${ss_method} -d start

    # 复制 Shadowsocks 配置文件到 /ect
    # mkdir -p /etc/shadowsocks
    # unalias cp
    # cp -f ${base_dir}/shadowsocks/config.json /etc/shadowsocks/config.json
    # alias cp='cp -i'

    # 配置服务
    # unalias cp
    # cp -f ${base_dir}/shadowsocks/shadowsocks.service /etc/systemd/system/shadowsocks.service
    # alias cp='cp -i'

    echo "配置服务..."
    cat >/etc/systemd/system/shadowsocks.service <<-EOF
[Unit]
Description=Shadowsocks
After=network.target

[Service]
Type=forking
ExecStart=/usr/bin/ssserver -s 0.0.0.0 -p ${ss_port} -k ${ss_pass} -m ${ss_method} -d start
ExecStop=/usr/bin/ssserver -d stop

[Install]
WantedBy=multi-user.target
EOF

    # 服务方式启动 Shadowshocks
    systemctl daemon-reload
    systemctl start shadowsocks
    systemctl enable shadowsocks

    # 将 Shadowsocks 的端口加入防火墙
    firewall-cmd --zone=public --add-port=${ss_port}/tcp --permanent
    firewall-cmd --zone=public --add-port=${ss_port}/udp --permanent

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
