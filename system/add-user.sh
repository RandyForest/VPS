# 当前文件夹路径
user_base_dir=$(
    cd $(dirname $0)
    pwd -P
)

# 加载环境变量
# source ${user_base_dir}/../env-var.sh

# 加载配置文件
source ${user_base_dir}/../config.sh

# 工具目录
tools_dir=${user_base_dir}/../tools

use_help() {
    cat <<-EOF
用法：  shadowsocks.sh [选项] 命令
选项：
    -a  自动模式
EOF
}

# 默认配置
# user_name_default=randy
# user_pass_default=rr

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
