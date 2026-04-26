#!/bin/bash
# task-book-keeper: 任务书加密备份脚本
# 前置：调用 core-asset-protection 确认 HC-AP1

set -e

# 密码存 ~/.backup-password（chmod 600），不推 GitHub，不备份
PASSWORD_FILE="$HOME/.backup-password"
if [ ! -f "$PASSWORD_FILE" ]; then
    echo "❌ 密码文件不存在: $PASSWORD_FILE"
    echo "   设置：echo 'omlx2046' > $PASSWORD_FILE && chmod 600 $PASSWORD_FILE"
    exit 1
fi
PASSWORD=$(cat "$PASSWORD_FILE")

BACKUP_MSG="${2:-task backup}"
TASK_DIR="tasks/audio-comic-skills"

# HC-AP1 检查：确认 .md 明文存在（本地永远保留）
cd "$(dirname "$0")/../.."
for file in "$TASK_DIR"/*.md; do
    if [ ! -f "$file" ]; then
        echo "⚠️ 警告：$file 不存在，本地明文缺失"
    fi
done

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

# 清理本地 .enc（不是 .md！GitHub 已有 .enc，本地保留 .md）
rm -f "$TASK_DIR"/*.enc

echo "✅ 备份完成（本地 .md 明文保留）"
