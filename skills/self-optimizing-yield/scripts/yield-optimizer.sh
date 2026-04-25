#!/bin/bash
# yield-optimizer.sh - 良品率优化脚本
# 批次结束后自动触发，统计良品率 + 经验入库 + 防退化

set -e

YIELD_DIR="${YIELD_DIR:-$HOME/.claude/yield}"
EXPERIENCE_DIR="$YIELD_DIR/experience"
ARCHIVE_DIR="$YIELD_DIR/archive"
mkdir -p "$YIELD_DIR" "$EXPERIENCE_DIR" "$ARCHIVE_DIR"

usage() {
    cat << 'EOF'
用法: yield-optimizer.sh <命令>

命令:
  record   记录本次批次良品率
  report   生成良品率报告
  history  查看历史趋势
  pattern  查看经验库
  rollback 检查是否触发防退化

示例:
  yield-optimizer.sh record --step 分镜 --passed 8 --total 10
  yield-optimizer.sh report
EOF
    exit 1
}

# --- 记录良品率 ---
record() {
    local STEP="" PASSED="" TOTAL=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --step) STEP="$2"; shift 2 ;;
            --passed) PASSED="$2"; shift 2 ;;
            --total) TOTAL="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    [ -z "$STEP" ] && { echo "❌ 需要 --step"; exit 1; }
    TOTAL="${TOTAL:-0}"
    PASSED="${PASSED:-0}"

    local RATE="0"
    if [ "$TOTAL" -gt 0 ]; then
        RATE=$(python3 -c "print(round($PASSED/$TOTAL*100, 1))")
    fi

    local TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local RECORD=$(python3 - "$STEP" "$PASSED" "$TOTAL" "$RATE" "$TS" << 'PYEOF'
import sys, json, datetime, os

step = sys.argv[1]
passed = int(sys.argv[2])
total = int(sys.argv[3])
rate = float(sys.argv[4])
ts = sys.argv[5]

yield_dir = os.path.expanduser("~/.claude/yield")
records_file = os.path.join(yield_dir, "records.jsonl")

record = {
    "step": step,
    "passed": passed,
    "total": total,
    "rate": rate,
    "timestamp": ts,
}

with open(records_file, "a", encoding="utf-8") as f:
    f.write(json.dumps(record, ensure_ascii=False) + "\n")

print(f"✅ 已记录: {step} {passed}/{total} ({rate}%)")
PYEOF
    )
    echo "$RECORD"
}

# --- 生成报告 ---
report() {
    python3 - << 'PYEOF'
import sys, json, os
from datetime import datetime, timedelta

records_file = os.path.expanduser("~/.claude/yield/records.jsonl")

if not os.path.exists(records_file):
    print("📊 良品率报告")
    print("=" * 40)
    print("(暂无记录)")
    sys.exit(0)

records = []
with open(records_file, encoding="utf-8") as f:
    for line in f:
        if line.strip():
            try:
                records.append(json.loads(line))
            except:
                pass

if not records:
    print("📊 良品率报告")
    print("=" * 40)
    print("(暂无记录)")
    sys.exit(0)

# 按环节分组统计
steps = {}
for r in records:
    s = r["step"]
    if s not in steps:
        steps[s] = {"passed": 0, "total": 0, "batches": 0}
    steps[s]["passed"] += r["passed"]
    steps[s]["total"] += r["total"]
    steps[s]["batches"] += 1

print("📊 良品率报告")
print("=" * 40)

total_passed = sum(v["passed"] for v in steps.values())
total_total = sum(v["total"] for v in steps.values())
overall = round(total_passed / total_total * 100, 1) if total_total > 0 else 0

print(f"总体良品率: {total_passed}/{total_total} ({overall}%)")
print(f"统计批次: {len(records)} 条")
print()

for step, v in steps.items():
    rate = round(v["passed"] / v["total"] * 100, 1) if v["total"] > 0 else 0
    mark = "✅" if rate >= 85 else ("⚠️" if rate >= 60 else "❌")
    print(f"  {mark} {step}: {v['passed']}/{v['total']} ({rate}%)")

# 趋势（最近7天）
recent_cutoff = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d")
recent = [r for r in records if r["timestamp"] >= recent_cutoff]
if recent:
    r_passed = sum(r["passed"] for r in recent)
    r_total = sum(r["total"] for r in recent)
    r_rate = round(r_passed / r_total * 100, 1) if r_total > 0 else 0
    print(f"\n近7天: {r_passed}/{r_total} ({r_rate}%)")

# 目标
print(f"\n目标: ≥95%")
print(f"当前差距: {round(95 - overall, 1)}%")
PYEOF
}

# --- 历史趋势 ---
history() {
    python3 - << 'PYEOF'
import sys, json, os
from datetime import datetime

records_file = os.path.expanduser("~/.claude/yield/records.jsonl")

if not os.path.exists(records_file):
    print("(暂无记录)"); sys.exit(0)

records = []
with open(records_file, encoding="utf-8") as f:
    for line in f:
        if line.strip():
            try:
                records.append(json.loads(line))
            except:
                pass

print("📈 良品率历史趋势")
print("=" * 50)
for r in records[-10:]:
    ts = r["timestamp"][:10]
    rate = r["rate"]
    mark = "✅" if rate >= 85 else ("⚠️" if rate >= 60 else "❌")
    print(f"  {ts} {mark} {r['step']}: {r['passed']}/{r['total']} ({rate}%)")
PYEOF
}

# --- 经验库 ---
pattern() {
    echo "📚 经验库"
    echo "================================"

    if [ ! -f "$EXPERIENCE_DIR/patterns.jsonl" ]; then
        echo "(空)"
        return
    fi

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local step=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin)['step'])" 2>/dev/null)
        local pattern=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin)['pattern'])" 2>/dev/null)
        echo "  • [$step] $pattern"
    done < "$EXPERIENCE_DIR/patterns.jsonl"
}

# --- 防退化检查 ---
rollback_check() {
    python3 - << 'PYEOF'
import sys, json, os
from collections import defaultdict

records_file = os.path.expanduser("~/.claude/yield/records.jsonl")

if not os.path.exists(records_file):
    print("✅ 无退化风险（无历史数据）")
    sys.exit(0)

records = []
with open(records_file, encoding="utf-8") as f:
    for line in f:
        if line.strip():
            try:
                records.append(json.loads(line))
            except:
                pass

# 按环节分组，取最近3条
steps = defaultdict(list)
for r in records:
    steps[r["step"]].append(r)

print("🔍 防退化检查")
print("=" * 40)

triggered = False
for step, recs in steps.items():
    recent = recs[-3:] if len(recs) >= 3 else recs
    if len(recent) < 3:
        print(f"  ⏳ {step}: 数据不足（{len(recent)}/3）")
        continue

    rates = [r["rate"] for r in recent]
    avg = sum(rates) / len(rates)

    # 连续下降检测
    decreasing = all(rates[i] < rates[i-1] for i in range(1, len(rates)))

    if decreasing and avg < 80:
        print(f"  🔴 {step}: 连续下降 {rates}，触发保护")
        triggered = True
    elif avg >= 85:
        print(f"  ✅ {step}: {avg}%（稳定）")
    else:
        print(f"  ⚠️  {step}: {avg}%（待提升）")

if not triggered:
    print("\n✅ 未触发防退化保护")
else:
    print("\n⚠️  建议回滚或调整参数")
PYEOF
}

# --- 主入口 ---
[ $# -lt 1 ] && usage
CMD="$1"; shift
case "$CMD" in
    record)   record "$@" ;;
    report)   report ;;
    history)  history ;;
    pattern)  pattern ;;
    rollback) rollback_check ;;
    *)        usage ;;
esac
