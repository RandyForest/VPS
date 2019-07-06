#!/usr/bin/bash
# CentOS-min shell 脚本

# 设置当前路径
basedir=$(
    cd $(dirname $0)
    pwd -P
)

# 安装函数
# 用法： installTool [-a] [-c 命令] 工具名
# 选项：
#   -a  设置测试参数
#   -c  设置用于测试的命令名称
installTool() {
    arg="--version"
    while [ -n "$1" ]; do
        case "$1" in
        -a)
            arg=$2
            shift
            ;;
        -c)
            cmd=$2
            shift
            ;;
        *)
            tool=$1
            ;;
        esac
        shift
    done

    if [ -z ${cmd} ]; then
        cmd=${tool}
    fi

    ${cmd} ${arg} >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "已安装 ${tool}"
    else
        echo "未检测到${tool}，正在安装${tool}..."
        yum -y install ${tool}
    fi
}

# 备份文件函数
# 用法：    backupFile 文件
backupFile() {
    echo "正在备份文件 $1"

    i=0
    while true; do
        if [ ! -f "$1.bak${i}" ]; then
            cp $1 $1.bak${i}
            if [ $? -eq 0 ]; then
                echo "备份完成，备份文件到 $1.bak${i}"
            else
                echo "备份失败！"
            fi
            break
        fi
        ((i++))
    done
}

## 设置 IP ##
setIp() {
    echo "# 设置 IP #"

    # 设置网关地址
    gateway=192.168.0.1

    # 设置IP地址
    ip=${gateway%.*}.21

    # 设置网卡名
    ifname=enp0s3
    # 设置网卡文件
    ifcfg=ifcfg-${ifname}

    # 备份并修改网卡文件
    backupFile /etc/sysconfig/network-scripts/${ifcfg}

    # 重启网络
    # service network restart

    # 使用 nmcli 命令修改 IP 配置

    # 添加 IP 地址
    nmcli connection modify ${ifname} +ipv4.addresses ${ip}/24

    # 添加 DNS
    nmcli connection modify ${ifname} +ipv4.dns 119.29.29.29
    nmcli connection modify ${ifname} +ipv4.dns 8.8.8.8

    # 添加网关
    nmcli connection modify ${ifname} ipv4.gateway ${gateway}

    # 设置手动获取 IP
    nmcli connection modify ${ifname} ipv4.method manual

    # 自动启动
    nmcli connection modify ${ifname} connection.autoconnect yes

    # 启动配置文件
    nmcli connection up ${ifname}

}

## 设置 DNS ##
setDns() {
    echo "# 设置 DNS #"

    backupFile /etc/resolv.conf

    echo "添加 DNS..."
    cat >>/etc/resolv.conf <<-EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 119.29.29.29
nameserver 233.5.5.5
EOF
}

## 设置 yum 源 ##
setRepo() {
    echo "# 设置 yum 源 #"

    # 安装 wget
    installTool wget

    # 备份
    backupFile /etc/yum.repos.d/CentOS-Base.repo

    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

    yum clean all

    yum makecache
}

## 更新及安装常用工具 ##
installTools() {
    echo "# 更新及安装常用工具 #"

    # 更新系统
    yum -y upgrade

    # 安装 epel-release
    yum -y install epel-release

    # 修改库源 /etc/yum.repos.d/epel.repo
    # sed -i 's|^#baseurl|baseurl|' /etc/yum.repos.d/epel.repo
    # sed -i 's|^mirrorlist|#mirrorlist|' /etc/yum.repos.d/epel.repo

    # 安装 sudo
    installTool sudo

    # 安装 vim
    installTool vim

    # 安装 firewall
    # yum -y install firewalld

    # 安装 net-tools
    installTool -c netstat net-tools

    # 安装 wget
    installTool wget

    # 安装 policycoreutils-python
    installTool -c semanage policycoreutils-python

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

    # 检查依赖

    installTool -c firewall-cmd firewalld

    installTool -c semanage policycoreutils-python

    # 设置 ssh 端口
    ssh_port=2222

    # 备份配置文件
    backupFile /etc/ssh/sshd_config

    # 修改 ssh 端口
    cat >>/etc/ssh/sshd_config <<-EOF

# 修改ssh端口
Port ${ssh_port}
EOF

    # 此配置文件修改了
    # ssh端口号 22 > 2222
    # cp ${basedir}/ssh/sshd_config /etc/ssh/sshd_config

    # 向 firewall 中添加端口 2222
    firewall-cmd --zone=public --add-port=2222/tcp --permanent

    # 重启 firewall
    firewall-cmd --reload

    # 在 SELinux 中添加 2222 端口
    semanage port -a -t ssh_port_t -p tcp 2222

    # 重启 ssh
    service sshd restart

}

## 添加用户 ##
addUser() {
    echo "# 添加用户 #"

    # 设置用户名
    user_name=randy
    user_pass=rr

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
    echo "# 安装 Tomcat #"

    echo "检查依赖..."
    # wget --version >/dev/null 2>&1
    # if [ $? -eq 0 ]; then
    #     echo "wget OK!"
    # else
    #     echo "未检测到wget，正在安装wget..."
    #     yum -y install wget
    # fi

    installTool wget

    # java --version >/dev/null 2>&1
    # if [ $? -eq 0 ]; then
    #     echo "java OK!"
    # else
    #     echo "未检测到java，正在安装java..."
    #     yum -y install java-11-openjdk
    # fi

    installTool -c java java-11-openjdk

    # firewall-cmd --version >/dev/null 2>&1
    # if [ $? -eq 0 ]; then
    #     echo "java OK!"
    # else
    #     # 安装 firewall
    #     echo "未检测到 firewall，正在安装 firewall ..."
    #     yum -y install firewalld
    #     systemctl restart dbus
    #     systemctl restart firewalld
    # fi

    installTool -c firewall-cmd firewalld

    echo "创建目录 /usr/local/tomcat"
    mkdir /usr/local/tomcat

    # 设置 Tomcat 的文件地址
    tomcat_file_url=http://mirror.bit.edu.cn/apache/tomcat/tomcat-9/v9.0.21/bin/apache-tomcat-9.0.21.tar.gz

    # 设置 Tomcat 文件夹名
    tomcat_homedir_name=$(echo $tomcat_file_url | grep -o "apache-tomcat-[0-9]\+\.[0-9]\+\.[0-9]\+")

    # 获取 Tomcat
    wget ${tomcat_file_url}

    # 解压 Tomcat
    echo "解压..."
    tar -z -x -f ${tomcat_file_url##*/} -C /usr/local/tomcat

    # 配置服务
    echo "配置服务..."
    cat >/etc/systemd/system/tomcat.service <<-EOF
[Unit]
Description=Tomcat test
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/tomcat/${tomcat_homedir_name}/bin/startup.sh
ExecStop=/usr/local/tomcat/${tomcat_homedir_name}/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl start tomcat
    systemctl enable tomcat

    # 向防火墙添加 80 端口,并将80端口的流量转到8080
    firewall-cmd --zone=public --add-port=80/tcp --permanent
    firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=8080 --permanent
    firewall-cmd --reload

}

## 安装 Shadowsocks ##
installSs() {
    echo "# 安装 Shadowsocks #"

    echo "检查依赖..."
    # pip --version >/dev/null 2>&1
    # if [ pip --version ]; then
    #     # 安装 pip
    #     yum -y install python-pip
    # fi

    installTool -c pip python-pip

    # if [ firewall-cmd --version ]; then
    #     # 安装 firewall
    #     yum -y install firewalld
    #     systemctl restart dbus
    #     systemctl restart firewalld

    # fi

    installTool -c firewall-cmd firewalld

    # 更新 pip
    pip install --upgrade pip

    # 安装 Shadowsocks
    pip install shadowsocks

    # 设置 Shadowsocks 端口
    ss_port=18989

    # 设置 Shadowsocks 密码
    ss_pass=123456

    # 设置 Shadowsocks 加密方法
    ss_method=aes-256-cfb

    # 命令行方式启动 Shadowsocks
    # ssserver -s 0.0.0.0 -p ${ss_port} -k ${ss_pass} -m ${ss_method} -d start

    # 复制 Shadowsocks 配置文件到 /ect
    mkdir -p /etc/shadowsocks
    unalias cp
    cp -f ${basedir}/shadowsocks/config.json /etc/shadowsocks/config.json
    alias cp='cp -i'

    # 配置服务
    unalias cp
    cp -f ${basedir}/shadowsocks/shadowsocks.service /etc/systemd/system/shadowsocks.service
    alias cp='cp -i'

    # 服务方式启动 Shadowshocks
    systemctl daemon-reload
    systemctl start tomcat
    systemctl enable tomcat

    # 将 Shadowsocks 的端口加入防火墙
    firewall-cmd --zone=public --add-port=${ss_port}/tcp --permanent
    firewall-cmd --zone=public --add-port=${ss_port}/udp --permanent
    firewall-cmd --zone=public --add-port=28989/tcp --permanent
    firewall-cmd --zone=public --add-port=28989/udp --permanent

    # 重启 firewall
    firewall-cmd --reload

}

## 安装 Shadowsocksr ##
installSsr() {
    echo "# 安装 Shadowsocksr #"

    # 安装依赖
    # git --version
    # if [ $? -ne 0 ]; then
    #     # 安装 git
    #     yum -y install git
    # fi

    installTool git

    # firewall-cmd --version
    # if [ $? -ne 0 ]; then
    #     # 安装 firewall
    #     yum -y install firewalld
    #     systemctl restart dbus
    #     systemctl restart firewalld

    # fi

    installTool -c firewall-cmd firewalld

    # 获取 Shadowsocksr
    git clone https://github.com/shadowsocksr-backup/shadowsocksr.git

    # 设置 Shadowsocksr 端口
    ssr_port=38989

    # 设置 Shadowsocksr 密码
    ssr_pass=123456

    # 设置 Shadowsocksr 加密方式
    ssr_method=aes-256-cfb

    # 设置 Shadowsocksr OBFS
    ssr_obfs=tls1.2_ticket_auth

    # 命令行方式启动 Shadowsocksr
    python shadowsocksr/shadowsocks/server.py -p ${ssr_port} -k ${ssr_pass} -m ${ssr_method} -o ${ssr_obfs} -d start

    # 复制 Shadowsocksr 配置文件到 /ect
    # cp -r shadowsocksr /etc

    # 以加载配置文件方式启动
    # python shadowsocksr/shadowsocks/server.py -c /etc/shadowsocksr/config.json -d start

    # 将 Shadowsocks 的端口加入防火墙
    firewall-cmd --zone=public --add-port=${ssr_port}/tcp --permanent
    firewall-cmd --zone=public --add-port=${ssr_port}/udp --permanent

    # 重启 firewall
    firewall-cmd --reload

}

## 安装 V2Ray ##
installV2ray() {
    echo "# 安装 V2Ray #"

    # 检查依赖
    # firewall-cmd --version
    # if [ $? -ne 0 ]; then
    #     # 安装 firewall
    #     yum -y install firewalld
    # fi

    installTool -c firewall-cmd firewalld

    # /usr/bin/v2ray/v2ray：V2Ray 程序；
    # /usr/bin/v2ray/v2ctl：V2Ray 工具；
    # /etc/v2ray/config.json：配置文件；
    # /usr/bin/v2ray/geoip.dat：IP 数据文件
    # /usr/bin/v2ray/geosite.dat：域名数据文件
    # /etc/systemd/system/v2ray.service: Systemd
    # /etc/init.d/v2ray: SysV
    bash <(curl https://install.direct/go.sh)

    # 设置 V2Ray 端口

    # 配置 V2Ray

    # 运行 V2Ray
    systemctl daemon-reload
    systemctl restart v2ray.service

    # 为 V2Ray 开启防火墙
    # Create new chain
    iptables -t nat -N V2RAY
    iptables -t mangle -N V2RAY
    iptables -t mangle -N V2RAY_MARK

    # Ignore your V2Ray server's addresses
    # It's very IMPORTANT, just be careful.
    iptables -t nat -A V2RAY -d 107.175.69.194 -j RETURN

    # Ignore LANs and any other addresses you'd like to bypass the proxy
    # See Wikipedia and RFC5735 for full list of reserved networks.
    iptables -t nat -A V2RAY -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A V2RAY -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A V2RAY -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A V2RAY -d 169.254.0.0/16 -j RETURN
    iptables -t nat -A V2RAY -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A V2RAY -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A V2RAY -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A V2RAY -d 240.0.0.0/4 -j RETURN
    iptables -t nat -A V2RAY -d 117.150.3.134 -j RETURN

    # Anything else should be redirected to Dokodemo-door's local port
    iptables -t nat -A V2RAY -p tcp -j REDIRECT --to-ports 8080

    # Add any UDP rules
    ip route add local default dev lo table 100
    ip rule add fwmark 1 lookup 100
    iptables -t mangle -A V2RAY -p udp --dport 53 -j TPROXY --on-port 12345 --tproxy-mark 0x01/0x01
    iptables -t mangle -A V2RAY_MARK -p udp --dport 53 -j MARK --set-mark 1

    # Apply the rules
    iptables -t nat -A OUTPUT -p tcp -j V2RAY
    iptables -t mangle -A PREROUTING -j V2RAY
    iptables -t mangle -A OUTPUT -j V2RAY_MARK

    # 将 Shadowsocks 的端口加入防火墙
    firewall-cmd --zone=public --add-port=${v2ray_port}/tcp --permanent
    firewall-cmd --zone=public --add-port=${v2ray_port}/udp --permanent

    # 重启 firewall
    firewall-cmd --reload

}

## 安装 kcptun ##
installKcptun() {
    echo "# 安装 kcptun #"

    # 检查依赖
    # wget --version
    # if [ $? -ne 0 ]; then
    #     yum -y install wget
    # fi

    installTool wget

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
    cp -f ${basedir}/kcptun/server-config.json /etc/kcptun/config.json
    alias cp='cp -i'

    # 启动 kcptun
    /usr/local/kcptun/server_linux_amd64 -c /etc/kcptun/config.json

}

## 安装 aria2 ##
installAria2() {
    echo "# 安装 aria2 #"

    # 复制 aria2 的配置文件目录，需要把配置文件先放入当前目录下
    cp -r ${basedir}/aria2 /etc

    # 安装 aria2
    yum install -y aria2

    # 配置 aria2
    aria2c --conf-path="/etc/aria2/aria2.conf"
}

# 入口
# setIp
setDns
# setRepo
installTools
setSsh
addUser
installTomcat
installSs
installSsr
# installV2ray
# installKcptun
# installAria2

# 更新系统
yum -y update
