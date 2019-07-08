# 设置当前路径
base_dir=$(
    cd $(dirname $0)
    pwd -P
)

# 设置PATH
PATH=${PATH}:${base_dir}:${base_dir}/tools
