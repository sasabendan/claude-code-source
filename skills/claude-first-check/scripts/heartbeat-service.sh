#!/bin/bash
# Heartbeat Service - 会话启动时检查 session gap，自动返回主线
# 调用方式：每次会话启动时执行（可在 CLAUDE.md 的 startup 阶段调用）
#
# 逻辑：
#   session_gap = now - ~/.claude/heartbeat.json mtime
#   gap > 3 分钟 → 自检，继续主线（更新 heartbeat-state.md）
#   gap ≤ 3 分钟 → HEARTBEAT_OK（无需干预）

set -e

HEARTBEAT_JSON="$HOME/.claude/heartbeat.json"

# CWD 自适应定位 heartbeat-state.md（优先级：① 环境变量 ② CWD 下 ③ 上级 tasks/* 下）
PROJECT_ROOT=$(find . -maxdepth 3 -name heartbeat-state.md -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo "")
if [ -z "$PROJECT_ROOT" ]; then
    PROJECT_ROOT="$(find . -maxdepth 3 -name CLAUDE.md -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null)"
fi
STATE_FILE="${HEARTBEAT_STATE_FILE:-${PROJECT_ROOT:+$PROJECT_ROOT/heartbeat-state.md}}"
[ -z "$STATE_FILE" ] && STATE_FILE="./heartbeat-state.md"

NOW=$(date +%Y-%m-%dT%H:%M:%S)

# --- 计算 session gap（分钟）---
LAST_MOD=$(stat -f %Sm -t %s "$HEARTBEAT_JSON" 2>/dev/null || stat -c %Y "$HEARTBEAT_JSON" 2>/dev/null)
NOW_SEC=$(date +%s)
GAP_MIN=$(( (NOW_SEC - LAST_MOD) / 60 ))

echo "[Heartbeat] gap=${GAP_MIN}min | now=$NOW"

if [ "$GAP_MIN" -gt 3 ]; then
    echo "[Heartbeat] 自检触发 → 继续主线当前节点"

    # 读取当前主线任务
    CURRENT_TASK=$(grep "^current_main_task:" "$STATE_FILE" 2>/dev/null | sed 's/^current_main_task: //' || echo "有声漫画 Skills 体系技术债务整理")

    # 更新 heartbeat-state.md
    python3 - <<EOF
import re

now = "$NOW"
gap = $GAP_MIN
state_file = "$STATE_FILE"

with open(state_file, 'r') as f:
    content = f.read()

content = re.sub(r'last_heartbeat_at: .*', f'last_heartbeat_at: {now}', content)
content = re.sub(r'last_session_end_at: .*', f'last_session_end_at: {now}', content)
content = re.sub(r'session_gap_minutes: .*', f'session_gap_minutes: {gap}', content)
content = re.sub(r'last_heartbeat_result: .*', f'last_heartbeat_result: SELF_CHECK_TRIGGERED (gap={gap}min > 3min)', content)

with open(state_file, 'w') as f:
    f.write(content)

print(f"heartbeat-state.md updated (gap={gap}min, SELF_CHECK)")
EOF

    echo "[Heartbeat] 自检完成 → 继续主线：$CURRENT_TASK"

    # 输出下一步建议
    echo "--- HEARTBEAT NEXT STEP ---"
    echo "SELF_CHECK: resume main task"
    echo "main_task: $CURRENT_TASK"

else
    echo "[Heartbeat] HEARTBEAT_OK（gap=${GAP_MIN}min）"
    python3 - <<EOF
import re

now = "$NOW"
gap = $GAP_MIN
state_file = "$STATE_FILE"

with open(state_file, 'r') as f:
    content = f.read()

content = re.sub(r'last_heartbeat_at: .*', f'last_heartbeat_at: {now}', content)
content = re.sub(r'session_gap_minutes: .*', f'session_gap_minutes: {gap}', content)
content = re.sub(r'last_heartbeat_result: .*', f'last_heartbeat_result: HEARTBEAT_OK', content)

with open(state_file, 'w') as f:
    f.write(content)

print(f"heartbeat-state.md updated (HEARTBEAT_OK, gap={gap}min)")
EOF
fi
