#!/bin/bash
# task-book-keeper: 任务书加密备份脚本

set -e

PASSWORD=$(security find-generic-password -s "claude-backup" -w 2>/dev/null) || {
    echo "❌ 无法从 Keychain 获取密码，请先设置：security add-generic-password -a claude-code-source-backup -s claude-backup -w <password>"
    exit 1
}
BACKUP_MSG="${2:-task backup}"

TASK_DIR="tasks/audio-comic-skills"

# 检查目录
if [ ! -d "$TASK_DIR" ]; then
    echo "❌ 任务目录不存在: $TASK_DIR"
    exit 1
fi

cd "$(dirname "$0")/../.."

# 加密并备份
for file in "$TASK_DIR"/*.md; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        enc_file="${file}.enc"
        
        # 加密
        echo "$PASSWORD" | openssl enc -aes-256-cbc -salt -pbkdf2 \
            -in "$file" -out "$enc_file" -pass stdin 2>/dev/null
        
        echo "✅ 已加密: $filename"
        
        # 添加到 git
        git add "$enc_file"
    fi
done

# 提交
git commit -m "backup: $BACKUP_MSG

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

# 推送
git push origin main

# 清理本地加密文件
rm -f "$TASK_DIR"/*.enc

echo "✅ 备份完成"
