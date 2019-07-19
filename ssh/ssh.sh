# ssh 配置脚本

# 临时根目录
ssh_root="/tmp/ssh"

# 是否自动
is_auto=0

# 配置
ssh_port=2222

# 帮助信息
use_help() {
    echo "用法：  ssh.sh [选项] 命令"
    echo "选项："
    echo "  -a  自动模式"
}

modifyPort() {
    if [ ${is_auto} -eq 0 ]; then
        read -p "输入ssh监听端口（默认：${ssh_port}）："
        ssh_port=${REPLY:-${ssh_port}}
    fi

    # 检查依赖
    bash ${tools_dir}/install-tool.sh -m firewall-cmd firewalld
    bash ${tools_dir}/install-tool.sh -m semanage -a "--help" policycoreutils-python

    # 备份配置文件
    bash ${tools_dir}/backup-file.sh /etc/ssh/sshd_config

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
main() {
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
}

main