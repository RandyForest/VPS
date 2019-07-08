# ssh 配置脚本

# 当前文件夹路径
ssh_base_dir=$(
    cd $(dirname $0)
    pwd -P
)

# 加载环境变量
source ${init-base_dir}/env-var.sh


use_help() {
    cat <<-EOF
用法：  ssh.sh [选项] 命令
选项：
    -a  自动模式
EOF
}

install() {
    echo "添加ssh端口"

    if [ ${is_manual} -eq 1 ]; then
        read -p "输入ssh监听端口：" ssh_port
        if [ -z "${ssh_port}" ]; then
            ssh_port=${ssh_port_default}
        fi
    else
        # 设置 ssh 端口
        echo "设置默认ssh监听端口 ${ssh_port_default}"
        ssh_port=${ssh_port_default}

    fi


    # 默认配置
    ssh_port_default=2222

    # 检查依赖
    bash install-tool.sh -m firewall-cmd firewalld
    bash install-tool.sh -m semanage -a "--help" policycoreutils-python

    if [ ${is_manual} -eq 1 ]; then
        read -p "输入ssh监听端口：" ssh_port
        if [ -z "${ssh_port}" ]; then
            ssh_port=${ssh_port_default}
        fi
    else
        # 设置 ssh 端口
        echo "设置默认ssh监听端口 ${ssh_port_default}"
        ssh_port=${ssh_port_default}

    fi

    # 备份配置文件
    bash backup-file.sh /etc/ssh/sshd_config

    # 修改 ssh 端口
    cat >>/etc/ssh/sshd_config <<-EOF

# 修改ssh端口
Port ${ssh_port}
EOF

    # 此配置文件修改了
    # ssh端口号 22 > 2222
    # cp ${base_dir}/ssh/sshd_config /etc/ssh/sshd_config

    # 向 firewall 中添加端口 2222
    firewall-cmd --zone=public --add-port=${ssh_port}/tcp --permanent

    # 重启 firewall
    firewall-cmd --reload

    # 在 SELinux 中添加 2222 端口
    semanage port -a -t ssh_port_t -p tcp ${ssh_port}

    # 重启 ssh
    service sshd restart
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
*) echo "未知命令！" ;;
esac
