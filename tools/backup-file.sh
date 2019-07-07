# 备份文件函数
# 用法：    backup-file.sh 文件
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