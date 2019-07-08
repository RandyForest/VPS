# Tomcat 配置脚本

# 当前文件夹路径
tomcat_base_dir=$(
    cd $(dirname $0)
    pwd -P
)

# 加载环境变量
source ${init-base_dir}/env-var.sh



use_help() {
    cat <<-EOF
用法：  tomcat.sh [选项] 命令
选项：
    -a  自动模式
EOF
}

install() {
    echo "安装 Tomcat"

    # 默认配置
    tomcat_file_url_default=$(bash load-config.sh -a "tomcat_file_url")

    if [ ${is_manual} -eq 1 ]; then
        read -p "输入Tomcat文件下载地址（默认版本：${tomcat_file_url_default##*/}）：" tomcat_file_url
        if [ -z "${tomcat_file_url}" ]; then
            tomcat_file_url=${tomcat_file_url_default}
        fi
    else
        echo "设置默认Tomcat文件下载地址 ${tomcat_file_url_default}"
        tomcat_file_url=${tomcat_file_url_default}
    fi

    echo "检查依赖..."
    bash install-tool.sh wget
    bash install-tool.sh -m java java-11-openjdk
    bash install-tool.sh -m firewall-cmd firewalld

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

# 入口
is_manual=1

if [ -z "$1" ]; then
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
