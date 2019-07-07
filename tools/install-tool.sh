# 安装脚本
# 用法： install-tool.sh [-a] [-m 命令] 工具名
# 选项：
#   -a  设置测试参数
#   -m  设置用于测试的命令名称

# 默认使用 --version 测试，如果返回0则表示存在该工具
arg="--version"
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
