# CentOS-min shell 脚本

setIp() {
    ## 设置IP ##
    echo "设置IP"

    # 设置网关地址
    gateway=192.168.0.1

    # 设置IP地址
    ip=${gateway%.*}.21

    # 设置网卡名
    ifname=enp0s3
    # 设置网卡文件
    ifcfg=ifcfg-${ifname}

    # 备份并修改网卡文件
    i=0
    while true; do
        if [ ! -f "/etc/sysconfig/network-scripts/${ifcfg}.bak${i}" ]; then
            cp /etc/sysconfig/network-scripts/${ifcfg} /etc/sysconfig/network-scripts/${ifcfg}.bak${i}
            break
        fi
        ((i++))
    done

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

installTools() {
    ## 更新及安装常用工具 ##
    echo "更新及安装常用工具"

    # 更新系统
    # yum -y upgrade

    # 安装 epel-release
    yum -y install epel-release

    # 修改库源 /etc/yum.repos.d/epel.repo

    # 安装 sudo
    yum -y install sudo

    # 安装 vim
    yum -y install vim

    # 安装 net-tools
    yum -y install net-tools

    # 安装 wget
    yum -y install wget

    # 安装 policycoreutils-python
    yum -y install policycoreutils-python

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

setSsh() {
    # 设置 ssh
    echo "设置 ssh"

    # 检查依赖
    firewall-cmd --version
    if [ $? -ne 0 ]; then
        yum -y install firewall-cmd
    fi

    if [ $? -ne 0 ]; then
        # 安装 policycoreutils-python
        yum -y install policycoreutils-python
    fi

    # 设置 ssh 端口
    ssh_port=2222

    # 修改 ssh 端口
    i=0
    while true; do
        if [ ! -f "/etc/ssh/sshd_config.bak${i}" ]; then
            cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak${i}
            break
        fi
        ((i++))
    done

    cat >>/etc/ssh/sshd_config <<-EOF

# 修改ssh端口
Port ${ssh_port}
EOF

    # 此配置文件修改了
    # ssh端口号 22 > 2222
    # cp ./ssh/sshd_config /etc/ssh/sshd_config

    # 向 firewall 中添加端口 2222
    firewall-cmd --zone=public --add-port=2222/tcp --permanent

    # 重启 firewall
    firewall-cmd --reload

    # 在 SELinux 中添加 2222 端口
    semanage port -a -t ssh_port_t -p tcp 2222

    # 重启 ssh
    service sshd restart

}

addUser() {
    # 添加用户 randy
    echo "添加新用户"

    # 设置用户名
    user_name=randy
    user_pass=rr

    useradd -r -m -p ${user_pass} ${user_name}
    if [ $? -ne 0 ]; then
        usermod -m -d /home/${user_name} ${user_name}
        echo "${user_pass}" | passwd --stdin ${user_name}
    fi
}

installTomcat() {
    ## 安装 Tomcat ##
    echo "安装 Tomcat"

    # 检查依赖
    wget --version
    if [ $? -ne 0 ]; then
        yum -y install wget
    fi

    java --version
    if [ $? -ne 0 ]; then
        # 安装 JDK
        yum -y install java-latest-openjdk
    fi

    firewall-cmd --version
    if [ $? -ne 0 ]; then
        yum -y install firewall-cmd
    fi

    mkdir /usr/local/tomcat

    # 设置 Tomcat 的文件地址
    tomcat_file_url=http://mirror.bit.edu.cn/apache/tomcat/tomcat-9/v9.0.21/bin/apache-tomcat-9.0.21.tar.gz

    # 设置 Tomcat 文件夹名
    tomcat_homedirname=$(echo $tomcat_file_url | grep -o "apache-tomcat-[0-9]\+\.[0-9]\+\.[0-9]\+")

    # 获取 Tomcat
    wget ${tomcat_file_url}

    # 解压 Tomcat
    tar -z -x -f ${tomcat_file_url##*/} -C /usr/local/tomcat

    # 配置服务
    cat >/etc/systemd/system/tomcat.service <<-EOF
[Unit]
Description=Tomcat test
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/tomcat/${tomcat_homedirname}/bin/startup.sh
ExeStop=/usr/local/tomcat/${tomcat_homedirname}/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl start tomcat
    systemctl enable tomcat

    # 向防火墙添加 80 端口
    firewall-cmd --zone=public --add-port=80/tcp --permanent

    # 将80端口的流量转到8080
    firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=8080 --permanent
    firewall-cmd --reload

}

installSs() {
    ## 安装 Shadowsocks ##
    echo "安装 Shadowsocks"

    # 安装依赖
    pip --version
    if [ $? -ne 0 ]; then
        # 安装 pip
        yum -y install python-pip
    fi

    firewall-cmd --version
    if [ $? -ne 0 ]; then
        yum -y install firewall-cmd
    fi

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
    cp -f ./shadowsocks/config.json /etc/shadowsocks/config.json

    # 配置服务
    mkdir -p /etc/systemd/system
    unalias cp
    cp -f ./shadowsocks/shadowsocks.service /etc/systemd/system/shadowsocks.service

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

installSsr() {
    ## 安装 Shadowsocksr ##
    echo "安装 Shadowsocksr"

    # 安装依赖
    git --version
    if [ $? -ne 0 ]; then
        # 安装 git
        yum -y install git
    fi

    # 获取 Shadowsocksr
    git clone -b manyuser https://github.com/shadowsocksr-backup/shadowsocksr.git

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

installV2ray() {
    ## 安装 V2Ray ##
    echo "安装 V2Ray"

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
    # systemctl daemon-reload && systemctl restart v2ray.service

    # 运行 V2Ray
    service v2ray start

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

installKcptun() {
    ## 安装 kcptun ##
    echo "安装 kcptun"

    # 检查依赖
    wget --version
    if [ $? -ne 0 ]; then
        yum -y install wget
    fi

    # 设置 kcptun 地址
    kcptun_url=https://github.com/xtaci/kcptun/releases/download/v20190611/kcptun-linux-amd64-20190611.tar.gz

    # 设置 kcptun 家地址
    kcptun_homename=$(echo ${kcptun_url} | grep -o "kcptun-linux-amd64-[0-9]\+")

    mkdir /usr/local/kcptun

    wget ${kcptun_url}

    tar -z -x -f ${kcptun_url##*/} -C /usr/local/kcptun

    # 配置 kcptun
    cp -f ./kcptun/server-config.json /etc/kcptun/config.json

    # 启动 kcptun
    ./server_linux_amd64 -c /etc/kcptun/config.json

}

installAria2() {
    ## 安装并配置 aria2 ##
    echo "安装并配置 aria2"

    # 复制 aria2 的配置文件目录，需要把配置文件先放入当前目录下
    cp -r ./aria2 /etc

    # 安装 aria2
    yum install -y aria2

    # 配置 aria2
    aria2c --conf-path="/etc/aria2/aria2.conf"
}

# 入口
setIp
installTools
setSsh
addUser
installTomcat
installSs
installSsr
# installV2ray
installKcptun
# installAria2

# 更新系统
# yum -y update
