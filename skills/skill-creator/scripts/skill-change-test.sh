#!/bin/bash
# Skill 修改自动测试脚本 v1.0
# 用法：bash skill-change-test.sh <skill-name>
# 示例：bash skill-change-test.sh supervision-anti-drift

set -e

SKILL="$1"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
KB_ROOT="$REPO_ROOT/tasks/audio-comic-skills/knowledge-base"
INDEX="$KB_ROOT/.index.jsonl"
BACKLINKS="$KB_ROOT/_backlinks.json"
SKILL_FILE="$REPO_ROOT/skills/$SKILL/SKILL.md"

# 安全递增函数（避免 set -e 下 ((var++)) 返回 1 的问题）
inc_pass()  { PASS=$((PASS+1)); }
inc_fail()  { FAIL=$((FAIL+1)); }
inc_warn()  { WARN=$((WARN+1)); }

# 参数检查
if [ -z "$SKILL" ]; then
  echo "用法：bash skill-change-test.sh <skill-name>"
  echo "示例：bash skill-change-test.sh supervision-anti-drift"
  exit 1
fi

# 检查 Skill 文件是否存在
if [ ! -f "$SKILL_FILE" ]; then
  echo "❌ FAIL: $SKILL_FILE 不存在"
  exit 1
fi

MODIFIED=$(stat -f %m "$SKILL_FILE" 2>/dev/null || stat -c %Y "$SKILL_FILE")
echo "=========================================="
echo "Skill Change Test: $SKILL"
echo "=========================================="
echo "文件: $SKILL_FILE"
echo "文件修改时间: $(date -r $MODIFIED '+%Y-%m-%d %H:%M:%S')"
echo ""

PASS=0; FAIL=0; WARN=0

# A. 索引同步检测
echo "--- A. 索引同步检测 ---"
# 用 Python 精确匹配 name 字段（技能可能在 entry_type=experience/skills/skill 中）
UPDATED=$(python3 -c "
import sys, json
for line in open('$INDEX'):
    try:
        e = json.loads(line.strip())
        name = e.get('name','')
        # name 字段以 skill 名开头（chinese-thinking 中文思维锚定 → 匹配 chinese-thinking）
        if name.startswith('$SKILL') and e.get('entry_type','') in ('skills','skill','experience'):
            print(e.get('updated',''))
            break
    except: pass
" 2>/dev/null || echo "")
if [ -n "$UPDATED" ] && [ "$UPDATED" != "None" ]; then
  UPDATED_TS=$(python3 -c "from datetime import datetime; print(int(datetime.strptime('$UPDATED','%Y-%m-%dT%H:%M:%SZ').timestamp()))" 2>/dev/null || echo "0")
  if [ "$UPDATED_TS" -ge "$MODIFIED" ]; then
    echo "✅ PASS: updated=$UPDATED"
    inc_pass
  else
    echo "❌ FAIL: updated=$UPDATED < modified=$(date -r $MODIFIED '+%Y-%m-%dT%H:%M:%SZ')"
    inc_fail
  fi
else
  echo "⚠️  WARN: 未在 .index.jsonl 中找到 $SKILL 条目"
  inc_warn
fi

# B. 功能可用性检测（索引命中，name 字段以 skill 名开头）
echo "--- B. 功能可用性检测 ---"
HITS=$(python3 -c "
import json
count=0
for line in open('$INDEX'):
    try:
        e=json.loads(line.strip())
        if e.get('name','').startswith('$SKILL'):
            count+=1
    except: pass
print(count)
" 2>/dev/null || echo "0")
if [ "$HITS" -ge 1 ]; then
  echo "✅ PASS: 索引命中 $HITS 条"
  inc_pass
else
  echo "❌ FAIL: 索引命中 0 条"
  inc_fail
fi
echo ""

# C. 反链一致性检测
echo "--- C. 反链一致性检测 ---"
if grep -q "\"$SKILL\":" "$BACKLINKS" 2>/dev/null; then
  BACKLINK_FILES=$(grep -A 50 "\"$SKILL\":" "$BACKLINKS" 2>/dev/null | grep '\.md"' | sed 's/.*"\([^"]*\)".*/\1/' | head -20)
  VALID=0; INVALID=0; TOTAL=0
  for f in $BACKLINK_FILES; do
    TOTAL=$((TOTAL+1))
    if [ -f "$KB_ROOT/$f" ]; then
      VALID=$((VALID+1))
    else
      INVALID=$((INVALID+1))
      echo "   ⚠️  无效反链: $f"
    fi
  done
  if [ "$INVALID" -eq 0 ]; then
    echo "✅ PASS: $TOTAL 条反链全部有效"
    inc_pass
  else
    echo "⚠️  WARN: $VALID 有效 / $INVALID 无效"
    inc_warn
  fi
else
  echo "⚠️  WARN: _backlinks.json 中无 $SKILL 记录"
  inc_warn
fi
echo ""

# 汇总
echo "=========================================="
echo "结果汇总: $PASS 通过 / $FAIL 失败 / $WARN 警告"
echo "=========================================="

if [ "$FAIL" -gt 0 ]; then
  echo "❌ 测试失败，请按 C19 处理：记入 fail-case → 修复"
  exit 1
else
  echo "✅ 全部通过"
  exit 0
fi
