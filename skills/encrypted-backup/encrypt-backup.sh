#!/bin/bash
# encrypted-backup.sh
# 将文件加密后备份到 Git，本地只保留明文
# 密码从 macOS Keychain 自动读取（security find-generic-password -s claude-backup -w）

set -e

# 参数检查
if [ $# -lt 2 ]; then
    echo "Usage: $0 <git_message> <file1> [file2] ..."
    exit 1
fi

# 从 Keychain 读取密码（本地存储，永不上云）
PASSWORD=$(security find-generic-password -s "claude-backup" -w 2>/dev/null) || {
    echo "❌ 无法从 Keychain 获取密码，请确认已存储：security add-generic-password -a claude-code-source-backup -s claude-backup -w <password>"
    exit 1
}

GIT_MESSAGE="$1"
shift
FILES=("$@")

# 加密并添加文件
for FILE in "${FILES[@]}"; do
    if [ ! -f "$FILE" ]; then
        echo "⚠️ 跳过不存在: $FILE"
        continue
    fi
    
    ENC_FILE="${FILE}.enc"
    
    # 加密
    echo "$PASSWORD" | openssl enc -aes-256-cbc -salt -pbkdf2 \
        -in "$FILE" -out "$ENC_FILE" -pass stdin
    
    echo "✅ 已加密: $FILE -> $ENC_FILE"
    
    # 添加到 git
    git add "$ENC_FILE"
done

# 提交
git commit -m "$GIT_MESSAGE"

# 推送
git push origin main

# 清理本地加密文件
for FILE in "${FILES[@]}"; do
    ENC_FILE="${FILE}.enc"
    if [ -f "$ENC_FILE" ]; then
        rm -f "$ENC_FILE"
        echo "🗑️ 已删除本地加密文件: $ENC_FILE"
    fi
done

echo "✅ 加密备份完成"
