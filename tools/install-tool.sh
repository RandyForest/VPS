# 安装脚本
# 用法： install-tool.sh [-a 参数] [-m 命令] 工具名
# 选项：
#   -a  设置测试参数
#   -m  设置用于测试的命令名称

CMD_INSTALL=""
CMD_UPDATE=""

# 默认使用 --version 测试，如果返回0则表示存在该工具
arg="--version"


# return 1: not apt, yum, or zypper
getPMT(){
    if [[ -n `command -v apt-get` ]];then
        CMD_INSTALL="apt-get -y -qq install"
        CMD_UPDATE="apt-get -qq update"
    elif [[ -n `command -v yum` ]]; then
        CMD_INSTALL="yum -y -q install"
        CMD_UPDATE="yum -q makecache"
    elif [[ -n `command -v zypper` ]]; then
        CMD_INSTALL="zypper -y install"
        CMD_UPDATE="zypper ref"
    else
        return 1
    fi
    return 0
}

installSoftware() {
    COMPONENT=$1
    if [[ -n $(command -v $COMPONENT) ]]; then
        return 0
    fi

    getPMT
    if [[ $? -eq 1 ]]; then
        colorEcho ${RED} "The system package manager tool isn't APT or YUM, please install ${COMPONENT} manually."
        return 1
    fi
    if [[ $SOFTWARE_UPDATED -eq 0 ]]; then
        colorEcho ${BLUE} "Updating software repo"
        $CMD_UPDATE
        SOFTWARE_UPDATED=1
    fi

    colorEcho ${BLUE} "Installing ${COMPONENT}"
    $CMD_INSTALL $COMPONENT
    if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "Failed to install ${COMPONENT}. Please install it manually."
        return 1
    fi
    return 0
}

while [ -n "$1" ]; do
    case "$1" in
    -a)
        arg=$2
        shift
        ;;
    -m)
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
    yum -q -y install ${tool}
fi
