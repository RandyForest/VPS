#!/usr/bin/env bash
# CentOS-min shell 脚本

# 当前文件夹路径
init_base_dir=$(
    cd $(dirname $0)
    pwd -P
)

# 工具目录
tools_dir=${init_base_dir}/tools

# 加载配置文件
source ${init_base_dir}/config.sh

# 是否自动
is_auto=0

## 设置 DNS ##
setDns() {
    echo "# 设置 DNS #"

    bash ${tools_dir}/backup-file.sh /etc/resolv.conf

    echo "添加 DNS..."
    cat >>/etc/resolv.conf <<-EOF
nameserver 8.8.8.8
nameserver 119.29.29.29
nameserver 233.5.5.5
EOF
}

## 设置 IP ##
setNetwork() {
    echo "# 设置 IP #"

    # 默认值
    gateway_default=192.168.0.1
    ip_default=192.168.0.21
    ifname_default=enp0s3
    dns_list_default=(8.8.8.8 119.29.29.29 233.5.5.5)

    if [ ${is_auto} -eq 0 ]; then
        echo "注意：更改IP会导致网络断开。"

        echo "网卡列表："
        nmcli device
        read -p "输入网卡（默认：${ifname_default}）：" ifname
        if [ -z "${ifname}" ]; then
            ifname=${ifname_default}
        fi

        read -p "输入IP地址（默认：${ip_default}）：" ip
        if [ -z "${ip}" ]; then
            ip=${ip_default}
        fi

        read -p "输入网关地址（默认：${gateway_default}）：" gateway
        if [ -z "${gateway}" ]; then
            gateway=${gateway_default}
        fi

        read -p "输入DNS（多个DNS以空格隔开）：" dns_list_tmp
        dns_list=(${dns_list_tmp})
        if [ -z "${dns_list}" ]; then
            dns_list=${dns_list_default}
        fi
    else
        echo "设置网卡为：${ifname_default}"
        ifname=${ifname_default}

        echo "设置IP为：${ip_default}"
        ifname=${ip_default}

        echo "设置网关为：${gateway_default}"
        ifname=${gateway_default}
        
        echo "设置DNS为：${dns_list_default}"
        ifname=${dns_list_default}

    fi

    # 设置网卡文件
    ifcfg=ifcfg-${ifname}

    # 备份网卡文件
    bash ${tools_dir}/backup-file.sh /etc/sysconfig/network-scripts/${ifcfg}

    # 重启网络
    # service network restart

    # 使用 nmcli 命令修改 IP 配置

    # 添加 IP 地址
    nmcli connection modify ${ifname} +ipv4.addresses ${ip}/24

    # 添加 DNS
    for dns in ${dns_list[@]}; do
        nmcli connection modify ${ifname} +ipv4.dns ${dns}
    done

    # 添加网关
    nmcli connection modify ${ifname} +ipv4.gateway ${gateway}

    # 设置手动获取 IP
    nmcli connection modify ${ifname} ipv4.method manual

    # 设置自动启动
    nmcli connection modify ${ifname} connection.autoconnect yes

    # 启动网卡连接
    nmcli connection up ${ifname}

}

## 设置 yum 源 ##
setRepo() {
    echo "# 设置 yum 源 #"

    # 安装 wget
    bash ${tools_dir}/install-tool.sh wget

    # 备份
    bash ${tools_dir}/backup-file.sh /etc/yum.repos.d/CentOS-Base.repo

    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

    yum clean all

    yum makecache
}

## 更新及安装常用工具 ##
installTools() {
    echo "# 更新及安装常用工具 #"

    # 更新系统
    yum -q -y upgrade

    # 安装 epel-release
    yum -q -y install epel-release

    yum clean all

    yum makecache

    # 修改库源 /etc/yum.repos.d/epel.repo
    # sed -i 's|^#baseurl|baseurl|' /etc/yum.repos.d/epel.repo
    # sed -i 's|^mirrorlist|#mirrorlist|' /etc/yum.repos.d/epel.repo

    # 安装 sudo
    bash ${tools_dir}/install-tool.sh sudo

    # 安装 vim
    bash ${tools_dir}/install-tool.sh vim

    # 安装 firewall
    bash ${tools_dir}/install-tool.sh -m firewall-cmd firewalld

    # 安装 net-tools
    bash ${tools_dir}/install-tool.sh -m netstat net-tools

    # 安装 wget
    bash ${tools_dir}/install-tool.sh wget

    # 安装 pip
    bash ${tools_dir}/install-tool.sh -m pip python-pip

    # 安装 policycoreutils-python
    bash ${tools_dir}/install-tool.sh -m semanage -a "--help" policycoreutils-python

    # 安装 gcc
    # yum install -y gcc

    # 安装 gcc-c++
    # yum install -y gcc-c++

    # 安装 kernel-devel
    # yum install -y kernel-devel

    # 安装 libgcrypt-devel
    # yum install -y libgcrypt-devel

    # 安装 libxml2-devel
    # yum install -y libxml2-devel

    # 安装 openssl-devel
    # yum install -y openssl-devel

    # 安装 gettext-devel
    # yum install -y gettext-devel

    # 安装 cppunit
    # yum install -y cppunit

}

## 添加用户 ##
addUser() {
    echo "# 添加用户 #"
}

## 设置 ssh ##
setSsh() {
    while true; do
        cat <<-EOF
###############################
    1. 添加端口
    q. 退出
###############################
EOF
        read -p "选择需要设置的项目：" opt
        case ${opt} in
        1) bash ${init_base_dir}/ssh/ssh.sh install ;;
        q) return ;;
        *) echo "未知选项！" ;;
        esac
    done
}

## 安装 Tomcat ##
installTomcat() {
    while true; do
        cat <<-EOF
###############################
    1. 安装 Tomcat
    q. 退出
###############################
EOF
        read -p "选择需要设置的项目：" opt
        case ${opt} in
        1) bash ${init_base_dir}/tomcat/tomcat.sh install ;;
        q) return ;;
        *) echo "未知选项！" ;;
        esac
    done
}

## 安装 Shadowsocks ##
installSs() {
    while true; do
        cat <<-EOF
###############################
    1. 安装 Shadowsocks
    q. 退出
###############################
EOF
        read -p "选择需要设置的项目：" opt
        case ${opt} in
        1) bash ${init_base_dir}/shadowsocks/shadowsocks.sh install ;;
        q) return ;;
        *) echo "未知选项！" ;;
        esac
    done
}

## 安装 Shadowsocksr ##
installSsr() {
    while true; do
        cat <<-EOF
###############################
    1. 安装 Shadowsocksr
    q. 退出
###############################
EOF
        read -p "选择需要设置的项目：" opt
        case ${opt} in
        1) bash ${init_base_dir}/shadowsocksr/shadowsocksr.sh install ;;
        q) return ;;
        *) echo "未知选项！" ;;
        esac
    done

}

## 安装 V2Ray ##
installV2ray() {
    while true; do
        cat <<-EOF
###############################
    1. 安装 V2Ray
    q. 退出
###############################
EOF
        read -p "选择需要设置的项目：" opt
        case ${opt} in
        1) bash ${init_base_dir}/v2ray/v2ray.sh install ;;
        q) return ;;
        *) echo "未知选项！" ;;
        esac
    done
}

## 安装 kcptun ##
installKcptun() {
    echo "# 安装 kcptun #"

    # 检查依赖
    # wget --version
    # if [ $? -ne 0 ]; then
    #     yum -y install wget
    # fi

    bash ${tools_dir}/install-tool.sh wget

    # 设置 kcptun 地址
    kcptun_url=https://github.com/xtaci/kcptun/releases/download/v20190611/kcptun-linux-amd64-20190611.tar.gz

    # 设置 kcptun 家地址
    kcptun_homename=$(echo ${kcptun_url} | grep -o "kcptun-linux-amd64-[0-9]\+")

    mkdir /usr/local/kcptun

    wget ${kcptun_url}

    tar -z -x -f ${kcptun_url##*/} -C /usr/local/kcptun

    # 配置 kcptun
    mkdir -p /etc/kcptun/
    unalias cp
    cp -f ${init_base_dir}/kcptun/server-config.json /etc/kcptun/config.json
    alias cp='cp -i'

    # 启动 kcptun
    /usr/local/kcptun/server_linux_amd64 -c /etc/kcptun/config.json

}

## 安装 aria2 ##
installAria2() {
    echo "# 安装 aria2 #"

    # 复制 aria2 的配置文件目录，需要把配置文件先放入当前目录下
    cp -r ${init_base_dir}/aria2 /etc

    # 安装 aria2
    yum install -y aria2

    # 配置 aria2
    aria2c --conf-path="/etc/aria2/aria2.conf"
}

# 根据配置初始化
# TODO
initOfConfig() {
    # init_arg=($(bash load-config.sh -a "tomcat_file_url"))
    read_opt init_arg[@]

    # bash ${init_base_dir}/ssh/ssh.sh -a install
    # bash ${init_base_dir}/tomcat/tomcat.sh -a install
    # bash ${init_base_dir}/shadowsocks/shadowsocks.sh -a install

}

# 读取选项
read_opt() {
    for opt in $@; do
        case ${opt} in
        0) initOfConfig ;;
        1) setNetwork ;;
        2) installTools ;;
        3) addUser ;;
        4) setSsh ;;
        5) installTomcat ;;
        6) installSs ;;
        7) installSsr ;;
        8) installV2ray ;;
        q) exit ;;
        *) echo "未知选项！" ;;
        esac
    done
}

# 入口
main() {
    while true; do
        cat <<-EOF
##############################################################
    0. 使用配置文件自动配置
    1. 设置网络
    2. 更新及安装常用应用
    3. 添加用户
    4. 配置ssh
    5. 配置Tomcat
    6. 配置Shadowsocks
    7. 配置Shadowsocksr
    8. 配置V2Ray
    q. 退出

提示：
    * 如果要使用配置文件自动部署，需把编号0放置首位
    * 多个选项用空格隔开
##############################################################
EOF
        read -p "选择需要设置的项目：" opt_tmp
        opt_list=(${opt_tmp})
        read_opt ${opt_list[@]}
    done

    # setRepo
    # installKcptun
    # installAria2

}
