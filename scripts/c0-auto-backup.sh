#!/bin/bash
# C0 自动备份脚本
# 每 5 分钟执行：GitHub 加密备份（主线）+ 本地明文备份
# C11: 每 5 分钟 GitHub 自动备份，密码 omlx2046，无需反复授权

set -e

PROJECT_DIR="/Users/jennyhu/claude-code-source"
BACKUP_DIR="$PROJECT_DIR/tasks/audio-comic-skills/backups"
PASSWORD="omlx2046"

cd "$PROJECT_DIR"

TIMESTAMP=$(date "+%Y%m%d_%H%M%S")

# 1. 本地明文备份（不加密，做好版本管理）
tar -czf "$BACKUP_DIR/backup_c0_local_${TIMESTAMP}.tar.gz" \
    tasks/audio-comic-skills/TASK_PROGRESS.md \
    tasks/audio-comic-skills/knowledge-base/ \
    skills/ 2>/dev/null || true

# 保留最近 10 份
ls -t "$BACKUP_DIR"/backup_c0_local_*.tar.gz 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true

# 2. GitHub 加密备份（主线任务相关）
ENCRYPTED_FILES=(
    "tasks/audio-comic-skills/TASK_REQUIREMENTS.md"
    "tasks/audio-comic-skills/TASK_PROGRESS.md"
    "tasks/audio-comic-skills/master-plan.md"
    "skills/"
)

for file in "${ENCRYPTED_FILES[@]}"; do
    if [ -e "$file" ]; then
        echo "$PASSWORD" | openssl enc -aes-256-cbc -salt -pbkdf2 \
            -in "$file" -out "${file}.enc" -pass stdin 2>/dev/null && \
            git add "${file}.enc"
    fi
done

# 3. 提交并推送
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    git commit -m "chore: C0 auto-backup $(date '+%Y-%m-%d %H:%M')

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
    git push origin main 2>/dev/null || echo "⚠️ git push 失败"
    # 清理本地 .enc
    for file in "${ENCRYPTED_FILES[@]}"; do
        [ -f "${file}.enc" ] && rm -f "${file}.enc"
    done
fi

echo "[$(date '+%Y-%m-%d %H:%M')] C0 备份完成"
