#!/usr/bin/bash
# CentOS-min shell 脚本

# 设置当前路径
base_dir=$(
    cd $(dirname $0)
    pwd -P
)

# 设置PATH
PATH=${PATH}:${base_dir}:${base_dir}/tools

## 设置 DNS ##
setDns() {
    echo "# 设置 DNS #"

    bash backup-file.sh /etc/resolv.conf

    echo "添加 DNS..."
    cat >>/etc/resolv.conf <<-EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 119.29.29.29
nameserver 233.5.5.5
EOF
}

## 设置 IP ##
setNetwork() {
    echo "# 设置 IP #"

    # 默认值
    # gateway_default=192.168.0.1
    ip_default=192.168.0.21
    ifname_default=enp0s3
    dns_list_default=(8.8.8.8 8.8.4.4 119.29.29.29 233.5.5.5)

    if [ ${is_manual} -eq 1 ]; then
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

        # read -p "输入网关地址（默认：${gateway_default}）：" gateway
        # if [ -z "${gateway}" ]; then
        #     gateway=${gateway_default}
        # fi

        read -p "输入dns（多个DNS以空格隔开）：" dns_list_tmp
        dns_list=($(ehco ${dns_list_tmp}))
        if [ -z "${dns_list}" ]; then
            dns_list=${dns_list_default}
        fi
    else
        echo "临时更改DNS..."
        setDns
        return
    fi

    # 设置网卡文件
    ifcfg=ifcfg-${ifname}

    # 备份并修改网卡文件
    bash backup-file.sh /etc/sysconfig/network-scripts/${ifcfg}

    # 重启网络
    # service network restart

    # 使用 nmcli 命令修改 IP 配置

    # 添加 IP 地址
    nmcli connection modify ${ifname} +ipv4.addresses ${ip}/24

    # 添加 DNS
    for dns in ${dns_list[@]}; do
        nmcli connection modify ${ifname} +ipv4.dns ${dns}
    done

    # nmcli connection modify ${ifname} +ipv4.dns 119.29.29.29
    # nmcli connection modify ${ifname} +ipv4.dns 8.8.8.8

    # 添加网关
    # nmcli connection modify ${ifname} ipv4.gateway ${gateway}

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
    bash install-tool.sh wget

    # 备份
    bash backup-file.sh /etc/yum.repos.d/CentOS-Base.repo

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

    # 修改库源 /etc/yum.repos.d/epel.repo
    # sed -i 's|^#baseurl|baseurl|' /etc/yum.repos.d/epel.repo
    # sed -i 's|^mirrorlist|#mirrorlist|' /etc/yum.repos.d/epel.repo

    # 安装 sudo
    bash install-tool.sh sudo

    # 安装 vim
    bash install-tool.sh vim

    # 安装 firewall
    bash install-tool.sh -m firewall-cmd firewalld

    # 安装 net-tools
    bash install-tool.sh -m netstat net-tools

    # 安装 wget
    bash install-tool.sh wget

    # 安装 pip
    bash install-tool.sh -m pip python-pip

    # 安装 policycoreutils-python
    bash install-tool.sh -m semanage -a "--help" policycoreutils-python

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

## 设置 ssh ##
setSsh() {
    echo "# 设置 ssh #"
    if [ ${is_manual} -eq 1 ]; then
        bash ${base_dir}/ssh/ssh.sh install
    else
        bash ${base_dir}/ssh/ssh.sh -a install
    fi

}

## 添加用户 ##
addUser() {
    echo "# 添加用户 #"

    # 默认配置
    user_name_default=randy
    user_pass_default=rr

    if [ ${is_manual} -eq 1 ]; then
        read -p "输入用户名（默认：${user_name_default}）：" user_name
        if [ -z "${user_name}" ]; then
            user_name=${user_name_default}
        fi

        read -p "输入密码（默认：${user_pass_default}）：" user_pass
        if [ -z "${user_pass}" ]; then
            user_name=${user_pass_default}
        fi
    else
        echo "设置默认用户名 ${user_name_default}"
        user_name=${user_name_default}

        echo "设置默认密码 ${user_pass_default}"
        user_pass=${user_pass_default}
    fi

    echo "创建用户 ${user_name}..."
    useradd -r -m ${user_name}
    if [ $? -ne 0 ]; then
        echo "用户已存在，修改用户..."
        usermod -m -d /home/${user_name} ${user_name}
    fi

    echo "添加密码 ${user_pass}..."
    echo "${user_pass}" | passwd --stdin ${user_name}

    echo "将用户加入 wheel 用户组..."
    usermod -aG wheel ${user_name}
}

## 安装 Tomcat ##
installTomcat() {
    if [ ${is_manual} -eq 1 ]; then
        bash ${base_dir}/tomcat/tomcat.sh install
    else
        bash ${base_dir}/tomcat/tomcat.sh -a install
    fi

}

## 安装 Shadowsocks ##
installSs() {
    echo "# 安装 Shadowsocks #"

    echo "检查依赖..."
    bash install-tool.sh -m pip python-pip
    bash install-tool.sh -m firewall-cmd firewalld

    # 更新 pip
    pip install --upgrade pip

    # 安装 Shadowsocks
    pip install shadowsocks

    # 默认配置
    # 默认 Shadowsocks 监听端口
    ss_port_default=18989

    # 默认 Shadowsocks 密码
    ss_pass_default=123456

    # 默认 Shadowsocks 加密方法
    ss_method_default=aes-256-cfb

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

## 安装 Shadowsocksr ##
installSsr() {
    echo "# 安装 Shadowsocksr #"

    echo "检查依赖..."
    bash install-tool.sh git
    bash install-tool.sh -m firewall-cmd firewalld

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

## 安装 V2Ray ##
installV2ray() {
    echo "# 安装 V2Ray #"

    if [ ${is_manual} -eq 1 ]; then
        bash ${base_dir}/v2ray/v2ray.sh.sh install
    else
        bash ${base_dir}/v2ray/v2ray.sh.sh -a install
    fi

}

## 安装 kcptun ##
installKcptun() {
    echo "# 安装 kcptun #"

    # 检查依赖
    # wget --version
    # if [ $? -ne 0 ]; then
    #     yum -y install wget
    # fi

    bash install-tool.sh wget

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
    cp -f ${base_dir}/kcptun/server-config.json /etc/kcptun/config.json
    alias cp='cp -i'

    # 启动 kcptun
    /usr/local/kcptun/server_linux_amd64 -c /etc/kcptun/config.json

}

## 安装 aria2 ##
installAria2() {
    echo "# 安装 aria2 #"

    # 复制 aria2 的配置文件目录，需要把配置文件先放入当前目录下
    cp -r ${base_dir}/aria2 /etc

    # 安装 aria2
    yum install -y aria2

    # 配置 aria2
    aria2c --conf-path="/etc/aria2/aria2.conf"
}

# 入口
# 手动设置标志
is_manual=1

while true; do
    cat <<-EOF
###############################
0. 自动模式
1. 设置网络
2. 更新及安装常用应用
3. 设置ssh
4. 添加用户
5. 安装Tomcat
6. 安装Shadowsocks
7. 安装Shadowsocksr
8. 安装V2Ray
q. 退出
###############################
EOF
    read -p "选择需要设置的项目：" opt
    case ${opt} in
    0) is_manual=0 ;;
    1) setNetwork ;;
    2) installTools ;;
    3) setSsh ;;
    4) addUser ;;
    5) installTomcat ;;
    6) installSs ;;
    7) installSsr ;;
    8) installV2ray ;;
    q) exit ;;
    *) echo "未知选项！" ;;
    esac
done

# setRepo
# installKcptun
# installAria2

# 更新系统
yum -y update
