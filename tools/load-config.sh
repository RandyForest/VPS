# 读取配置文件

# 配置文件路径
config_file=${base_dir}/config.txt

use_help() {
    cat <<-EOF
用法：  load-config.sh 文件
选项：
    -a  需要读取的参数
EOF
}

read_arg() {
    line=$(grep -o "$1=.*" ${config_file})
    echo "${line#*=}"
}

# 入口
while [ -n "$1" ]; do
    case "$1" in
    -a)
        ehco "输入的参数是：$2"
        read_arg $2
        shift
        ;;
    *)
        echo "未知参数！"
        ;;
    esac
    shift
done
