#!/bin/bash
# 心跳脚本，每3分钟执行一次
# 检查主线任务进度，写入心跳文件

HEARTBEAT_FILE="$HOME/.claude/heartbeat.json"
PROJECT_DIR="/Users/jennyhu/claude-code-source"

# 检查当前会话是否有活动
# 如果有最近的 git 操作，说明在活跃状态

LAST_GIT=$(stat -f "%Sm" -t "%Y" "$PROJECT_DIR/.git/FETCH_HEAD" 2>/dev/null || echo "0")
NOW=$(date +%s)
GAP=$((NOW - LAST_GIT))

# 每3分钟（180秒）记录一次心跳，标记主线当前进度摘要
python3 -c "
import json, datetime
gap = int('$GAP')
heartbeat = {
    'timestamp': datetime.datetime.now().isoformat(),
    'main_branch': 'main',
    'git_gap_seconds': gap,
    'status': 'idle' if gap > 180 else 'active',
    'last_commit': '$(git -C $PROJECT_DIR log --oneline -1 --format="%H %s" 2>/dev/null)',
    'uncommitted_changes': bool('$(git -C $PROJECT_DIR status --porcelain 2>/dev/null)')
}
with open('$HEARTBEAT_FILE', 'w') as f:
    json.dump(heartbeat, f, indent=2, ensure_ascii=False)
" 2>/dev/null
