# CentOS-min shell 脚本
# 需要外部文件夹：
# - aria2
# - shadowsocks

## 设置IP ##
# 备份并修改网卡文件 ifcfg-enp0s3
# cp /etc/sysconfig/network-scripts/ifcfg-enp0s3 /etc/sysconfig/network-scripts/ifcfg-enp0s3.bak
# sed -i "s/^BOOTPROTO=.*$/BOOTPROTO=static" /etc/sysconfig/network-script/ifcfg-enp0s3
# sed -i "s/^ONBOOT=.*$/ONBOOT=yes" /etc/sysconfig/network-script/ifcfg-enp0s3
# echo "IPADDR=192.168.0.20" >> /etc/sysconfig/network-script/ifcfg-enp0s3
# echo "NETMASK=255.255.255.0" >> /etc/sysconfig/network-script/ifcfg-enp0s3
# echo "NETWORK=192.168.0.0" >> /etc/sysconfig/network-script/ifcfg-enp0s3
# echo "BROADCAST=192.168.0.255" >> /etc/sysconfig/network-script/ifcfg-enp0s3
# echo "GATEWAY=192.168.0.1" >> /etc/sysconfig/network-script/ifcfg-enp0s3
# echo "DNS1=119.29.29.29" >> /etc/sysconfig/network-script/ifcfg-enp0s3
# echo "DNS2=8.8.8.8" >> /etc/sysconfig/network-script/ifcfg-enp0s3

# 修改 DNS
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# 重启网络
# service network restart

# 更新系统
yum -y upgrade

# 安装 epel-release
yum -y install epel-release

# 修改库源 /etc/yum.repos.d/epel.repo

# 修改 ssh 端口
echo "Port 1022" >> /etc/ssh/sshd_config

# 添加用户 randy
useradd -g wheel -m -p rr randy

# 安装 net-tools
yum -y install net-tools

# 向 firewall 中添加端口 1022
firewall-cmd --zone=public --add-port=1022/tcp --permanent

# 重启 firewall
firewall-cmd --complete-reload

# 安装 policycoreutils-python
yum -y install policycoreutils-python

# 在 SELinux 中添加 ssh 端口
semanage port -a -t ssh_port_t -p tcp 1022

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

# 安装 pip
yum -y install python-pip

# 更新 pip
pip install --upgrade pip

# 安装 Shadowsocks
pip install shadowsocks

# 命令行方式启动 Shadowsocks
ssserver -s 0.0.0.0 -p 18989 -k 123456 -m aes-256-cfb -d start

# 复制 Shadowsocks 配置文件到 /ect/Shadowsocks
# cp -r shadowsocks /etc

# 启动 Shadowshocks
# ssserver -c /etc/shadowsocks/shadowsocks.json -d start

# 安装 git
yum -y install git

# 获取 Shadowsocksr
git clone -b manyuser https://github.com/shadowsocksr-backup/shadowsocksr.git

# 命令行方式启动 Shadowsocksr
python shadowsocksr/shadowsocks/server.py -p 443 -k 123456 -m aes-256-cfb -O auth_aes128_md5 -o tls1.2_ticket_auth -d start

# 以加载配置文件方式启动
# python shadowsocksr/shadowsocks/server.py

## 安装 V2Ray ##
bash <(curl https://install.direct/go.sh)

# 配置 V2Ray
# systemctl daemon-reload && systemctl restart v2ray.service

# 运行 V2Ray
service v2ray start

## 安装 kcptun ##
mkdir /root/kcptun

cd /root/kcptun

wget https://github.com/xtaci/kcptun/releases/download/v20190611/kcptun-linux-amd64-20190611.tar.gz

tar -zxvf kcptun-linux-amd64-20190611.tar.gz

# 配置 kcptun

# 启动 kcptun
./server_linux_amd64 -c /root/kcptun/server-config.json

cd ~

# 将 Shadowsocks 的端口加入防火墙
firewall-cmd --zone=public --add-port=18989/tcp --permanent
firewall-cmd --zone=public --add-port=18989/udp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
firewall-cmd --zone=public --add-port=443/udp --permanent

# 重启 firewall
firewall-cmd --complete-reload

## 安装并配置 aria2 ##
# 复制 aria2 的配置文件目录，需要把配置文件先放入当前目录下
cp -r ./aria2 /etc

# 安装 aria2
yum install -y aria2

# 配置 aria2
# aria2c --conf-path="/etc/aria2/aria2.conf"

# 更新系统
yum -y update