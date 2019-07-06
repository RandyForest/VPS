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

    if [ -z "${cmd}" ]; then
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

## 设置 IP ##
setNetwork() {
    echo "# 设置 IP #"

    # 默认值
    # gateway_default=192.168.0.1
    ip_default=192.168.0.21
    ifname_default=enp0s3
    dns_list_default=(8.8.8.8 8.8.4.4 119.29.29.29 233.5.5.5)

    if [ ${isManual} -eq 1 ]; then
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

        read -p "输入dns（多个DNS以空格隔开）：" dns_list
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
    backupFile /etc/sysconfig/network-scripts/${ifcfg}

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

    # 默认配置
    ssh_port_default=2222

    # 检查依赖
    installTool -c firewall-cmd firewalld
    installTool -c semanage policycoreutils-python

    if [ ${isManual} -eq 1 ]; then
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
    firewall-cmd --zone=public --add-port=${ssh_port}/tcp --permanent

    # 重启 firewall
    firewall-cmd --reload

    # 在 SELinux 中添加 2222 端口
    semanage port -a -t ssh_port_t -p tcp ${ssh_port}

    # 重启 ssh
    service sshd restart

}

## 添加用户 ##
addUser() {
    echo "# 添加用户 #"

    # 默认配置
    user_name_default=randy
    user_pass_default=rr

    if [ ${isManual} -eq 1 ]; then
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
    echo "# 安装 Tomcat #"

    echo "检查依赖..."
    installTool wget
    installTool -c java java-11-openjdk
    installTool -c firewall-cmd firewalld

    # 默认配置
    tomcat_file_url_default=http://mirror.bit.edu.cn/apache/tomcat/tomcat-9/v9.0.21/bin/apache-tomcat-9.0.21.tar.gz

    if [ ${isManual} -eq 1 ]; then
        read -p "输入Tomcat文件下载地址（默认版本：${tomcat_file_url##*/}）：" tomcat_file_url
        if [ -z "${tomcat_file_url}" ]; then
            tomcat_file_url=${tomcat_file_url_default}
        fi
    else
        echo "设置默认Tomcat文件下载地址 ${tomcat_file_url_default}"
        tomcat_file_url=${tomcat_file_url_default}
    fi

    echo "创建目录 /usr/local/tomcat"
    mkdir /usr/local/tomcat

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
    installTool -c pip python-pip
    installTool -c firewall-cmd firewalld

    # 更新 pip
    pip install --upgrade pip

    # 安装 Shadowsocks
    pip install shadowsocks

    # 默认配置
    # 默认 Shadowsocks 监听端口
    ss_port_defualt=18989

    # 默认 Shadowsocks 密码
    ss_pass_defualt=123456

    # 默认 Shadowsocks 加密方法
    ss_method_defualt=aes-256-cfb

    if [ ${isManual} -eq 1 ]; then
        read -p "输入 Shadowsocks 监听端口（默认：${ss_port_defualt}）：" ss_port
        if [ -z "${ss_port}" ]; then
            ss_port=${ss_port_defualt}
        fi

        read -p "输入 Shadowsocks 密码（默认：${ss_pass_defualt}）：" ss_pass
        if [ -z "${ss_pass}" ]; then
            ss_pass=${ss_pass_defualt}
        fi

        read -p "输入 Shadowsocks 加密方法（默认：${ss_method_defualt}）：" ss_method
        if [ -z "${ss_method}" ]; then
            ss_method=${ss_method_defualt}
        fi
    else
        echo "设置默认 Shadowsocks 监听端口：${ss_port_defualt}"
        ss_port=${ss_port_defualt}

        echo "设置默认 Shadowsocks 密码：${ss_pass_defualt}"
        ss_pass=${ss_pass_defualt}

        echo "设置默认 Shadowsocks 加密方法：${ss_method_defualt}"
        ss_method=${ss_method_defualt}
    fi

    # 命令行方式启动 Shadowsocks
    # ssserver -s 0.0.0.0 -p ${ss_port} -k ${ss_pass} -m ${ss_method} -d start

    # 复制 Shadowsocks 配置文件到 /ect
    # mkdir -p /etc/shadowsocks
    # unalias cp
    # cp -f ${basedir}/shadowsocks/config.json /etc/shadowsocks/config.json
    # alias cp='cp -i'

    # 配置服务
    # unalias cp
    # cp -f ${basedir}/shadowsocks/shadowsocks.service /etc/systemd/system/shadowsocks.service
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
    installTool git
    installTool -c firewall-cmd firewalld

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

    if [ ${isManual} -eq 1 ]; then
        read -p "输入 Shadowsocks 监听端口（默认：${ssr_port_defualt}）：" ssr_port
        if [ -z "${ssr_port}" ]; then
            ssr_port=${ssr_port_defualt}
        fi

        read -p "输入 Shadowsocks 密码（默认：${ssr_port_defualt}）：" ssr_pass
        if [ -z "${ssr_pass}" ]; then
            ssr_pass=${ssr_pass_defualt}
        fi

        read -p "输入 Shadowsocks 加密方法（默认：${ssr_port_defualt}）：" ssr_method
        if [ -z "${ssr_method}" ]; then
            ssr_method=${ssr_method_defualt}
        fi

        read -p "输入 Shadowsocks OBFS（默认：${ssr_obfs_default}）：" ssr_obfs
        if [ -z "${ssr_obfs}" ]; then
            ssr_obfs=${ssr_obfs_default}
        fi
    else
        echo "设置默认 Shadowsocks 监听端口：${ssr_port_defualt}"
        ssr_port=${ssr_port_defualt}

        echo "设置默认 Shadowsocks 密码：${ssr_pass_defualt}"
        ssr_pass=${ssr_pass_defualt}

        echo "设置默认 Shadowsocks 加密方法：${ssr_method_defualt}"
        ssr_method=${ssr_method_defualt}

        echo "设置默认 Shadowsocks OBFS：${ssr_obfs_default}"
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

    # 服务方式启动 Shadowshocks
    systemctl daemon-reload
    systemctl start shadowsocksr
    systemctl enable shadowsocksr

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
    installTool -c firewall-cmd firewalld

    # /usr/bin/v2ray/v2ray：V2Ray 程序；
    # /usr/bin/v2ray/v2ctl：V2Ray 工具；
    # /etc/v2ray/config.json：配置文件；
    # /usr/bin/v2ray/geoip.dat：IP 数据文件
    # /usr/bin/v2ray/geosite.dat：域名数据文件
    # /etc/systemd/system/v2ray.service: Systemd
    # /etc/init.d/v2ray: SysV
    bash <(curl https://install.direct/go.sh) | tee /tmp/v2ray_install.log

    port_tmp=$(grep "^PORT:[0-9]\+" /tmp/v2ray_install.log | grep -o "[0-9]\+")

    # 默认配置
    v2ray_port_default=58989
    v2ray_uuid_default=67ff0138-4873-4b0c-912d-a8649b24ecaa

    if [ ${isManual} -eq 1 ]; then
        read -p "输入V2Ray端口（默认：${v2ray_port_default}）：" v2ray_port
        if [ -z "${ssr_obfs}" ]; then
            v2ray_port=${v2ray_port_default}
        fi

        read -p "输入V2Ray UUID（默认：${v2ray_uuid_default}）：" v2ray_uuid
        if [ -z "${ssr_obfs}" ]; then
            v2ray_uuid=${v2ray_uuid_default}
        fi
    else
        echo "设置默认V2Ray端口：${v2ray_port_default}"
        v2ray_port=${v2ray_port_default}

        echo "设置默认V2Ray UUID：${v2ray_uuid_default}"
        v2ray_uuid=${v2ray_uuid_default}
    fi

    # 修改端口
    sed -i 's/\"port\":${port_tmp}.*/\"port\":${v2ray_port}/' /etc/v2ray/config.json

    # 修改UUID
    sed -i 's/\"id\":.*/\"id\":${v2ray_uuid}/' /etc/v2ray/config.json

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
read -p "是否手动设置？："
if [ "$REPLY" = "y" ]; then
    echo "进入手动设置..."
    isManual=1
else
    echo "进入自动设置..."
fi

setNetwork
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
