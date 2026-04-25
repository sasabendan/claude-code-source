#!/bin/bash
# supervisor.sh - 监督验收脚本
# 包裹任务执行，自动做 NCA + checkpoint + 漂移检测 + 审计

set -e

SUPERVISION_DIR="${SUPERVISION_DIR:-$HOME/.claude/supervision}"
LOGS_DIR="$SUPERVISION_DIR/logs"
CHECKPOINTS_DIR="$SUPERVISION_DIR/checkpoints"
REPORTS_DIR="$SUPERVISION_DIR/reports"

mkdir -p "$LOGS_DIR" "$CHECKPOINTS_DIR" "$REPORTS_DIR"

usage() {
    cat << 'EOF'
用法: supervisor.sh <命令> [选项]

命令:
  wrap     包裹任务执行（核心）
  check    NCA 手动检查
  status   当前状态
  rollback 回滚
  report   查看报告

wrap 示例:
  supervisor.sh wrap --task 分镜设计 --spec "生成10个分镜" --executor "cat file.txt"
EOF
    exit 1
}

run_id() { date +%Y%m%d_%H%M%S_$$; }
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }

# --- NCA 必要条件 ---
nca() {
    local TASK="$1" OUTPUT="$2" SPEC="$3" COST="$4" BUDGET="${5:-100}"
    local PASS=1 LINE=""

    case "$TASK" in
        脚本生成)
            if [ -f "$OUTPUT" ]; then
                local actual=$(wc -c < "$OUTPUT")
                local expected=${expected:-$(echo "$SPEC" | grep -oE '[0-9]+' | head -1)}
                [ -z "$expected" ] && expected=1000
                local err=$(python3 -c "print(abs($actual-$expected)/$expected*100)")
                if python3 -c "exit(0 if float('$err')<10 else 1)" 2>/dev/null; then
                    LINE="✅ 字数误差: ${err}% (<10%)"
                else
                    LINE="❌ 字数误差: ${err}% (>=10%)"; PASS=0
                fi
            fi
            ;;
        分镜设计)
            if [ -f "$OUTPUT" ]; then
                local count=$(grep -c "场景\|【" "$OUTPUT" 2>/dev/null || echo 0)
                LINE="✅ 场景检查: $count 处标记"
            fi
            ;;
        生图)
            if [ -f "$OUTPUT" ]; then
                local has=$(grep -c "风格\|漫画\|style" "$OUTPUT" 2>/dev/null || echo 0)
                LINE="✅ 风格标记: $has 处"
            fi
            ;;
        配音)
            if [ -f "$OUTPUT" ]; then
                local has=$(grep -c "情感\|emotion\|happy\|sad" "$OUTPUT" 2>/dev/null || echo 0)
                LINE="✅ 情感标记: $has 处"
            fi
            ;;
        *)
            if [ -f "$OUTPUT" ]; then
                LINE="✅ 输出存在"
            else
                LINE="❌ 输出不存在"; PASS=0
            fi
            ;;
    esac

    echo "$LINE"
    [ "$PASS" -eq 1 ]
}

# --- 漂移检测（兼容中文）---
drift() {
    local SPEC="$1" ACTUAL="$2" THRESHOLD="${3:-0.15}"

    # 用 Python 提取关键词，避免 macOS grep 中文兼容问题
    local RESULT
    RESULT=$(python3 -c "
import sys, re
spec = sys.argv[1]
actual = sys.argv[2] if len(sys.argv) > 2 else ''
threshold = float(sys.argv[3]) if len(sys.argv) > 3 else 0.15

# 提取中英文关键词（2字符以上）
keywords = re.findall(r'[\u4e00-\u9fa5a-zA-Z]{2,}', spec)
kw_set = sorted(set(kw.lower() for kw in keywords))

total = len(kw_set)
if total == 0:
    print('unknown')
    sys.exit(2)

matched = 0
if actual:
    try:
        with open(actual, 'r', encoding='utf-8') as f:
            content = f.read().lower()
        for kw in kw_set:
            if kw in content:
                matched += 1
    except:
        pass

coverage = round(matched / total, 3) if total > 0 else 0
drift_val = round(1 - coverage, 3)
print(f'{matched}/{total} {coverage} {drift_val}')
" "$SPEC" "$ACTUAL" "$THRESHOLD" 2>/dev/null)

    local matched_total=$(echo "$RESULT" | awk '{print $1}')
    local coverage=$(echo "$RESULT" | awk '{print $2}')
    local drift_val=$(echo "$RESULT" | awk '{print $3}')

    if [ "$drift_val" = "unknown" ]; then
        echo "drift_verdict: unknown"; return 2
    fi

    if python3 -c "exit(0 if float('$drift_val')<=$THRESHOLD else 1)" 2>/dev/null; then
        echo "关键词: $matched_total 覆盖率: $coverage 漂移值: $drift_val"
        echo "drift_verdict: pass"
        return 0
    else
        echo "关键词: $matched_total 覆盖率: $coverage 漂移值: $drift_val"
        echo "drift_verdict: drift_detected"
        return 1
    fi
}

# --- 包裹执行 ---
wrap() {
    local TASK="" SPEC="" EXECUTOR="" BUDGET=100

    while [ $# -gt 0 ]; do
        case "$1" in
            --task) TASK="$2"; shift 2 ;;
            --spec) SPEC="$2"; shift 2 ;;
            --executor) EXECUTOR="$2"; shift 2 ;;
            --budget) BUDGET="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    [ -z "$TASK" ] && [ -z "$SPEC" ] && { echo "❌ 需要 --task 和 --spec"; exit 1; }

    local ID=$(run_id)
    local LOG="$LOGS_DIR/${ID}.log"
    local CP="$CHECKPOINTS_DIR/${ID}.json"
    local REP="$REPORTS_DIR/${ID}.md"

    echo "🔍 监督: $TASK (ID: $ID)"
    echo "📋 Spec: $SPEC"

    # 执行
    if [ -n "$EXECUTOR" ]; then
        echo "⚙️ 执行: $EXECUTOR"
        eval "$EXECUTOR" > "$LOG" 2>&1 || true
    else
        cat > "$LOG"
    fi

    # NCA
    echo "🔬 NCA 检查..."
    local NCA_OUT; NCA_OUT=$(nca "$TASK" "$LOG" "$SPEC")
    echo "   $NCA_OUT"
    local NCA_PASS=$?

    # 漂移
    echo "🌊 漂移检测..."
    local DRIFT_OUT; DRIFT_OUT=$(drift "$SPEC" "$LOG")
    echo "   $DRIFT_OUT"

    # 写 checkpoint
    cat > "$CP" << JSONEOF
{"run_id":"$ID","task":"$TASK","spec":"$SPEC","spec_hash":"$(sha "$LOG")","log":"$LOG","nca_pass":$NCA_PASS,"drift":"$(echo "$DRIFT_OUT" | grep drift_verdict | cut -d: -f2 | tr -d ' ')","timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
JSONEOF

    # 写报告
    cat > "$REP" << EOF
# 验收报告: $TASK

**ID**: $ID  
**时间**: $(date '+%Y-%m-%d %H:%M:%S')

## Spec

$SPEC

## NCA 检查

$NCA_OUT

## 漂移检测

$DRIFT_OUT

## 日志

$LOG

*由 supervision-anti-drift skill 自动生成*
EOF

    # 判定
    echo "================================"
    local VERDICT="pass"
    [ $NCA_PASS -ne 0 ] && VERDICT="fail"
    echo "$DRIFT_OUT" | grep -q "drift_detected" && VERDICT="drift_detected"
    echo "📊 判定: $VERDICT"
    echo "📄 报告: $REP"
    echo "================================"

    [ "$VERDICT" = "pass" ]
}

# --- 状态 ---
status() {
    echo "📊 监督状态 ($(date '+%H:%M:%S'))"
    echo "Checkpoint: $(ls $CHECKPOINTS_DIR 2>/dev/null | wc -l | tr -d ' ') 个"
    echo "日志: $(ls $LOGS_DIR 2>/dev/null | wc -l | tr -d ' ') 个"
    echo "报告: $(ls $REPORTS_DIR 2>/dev/null | wc -l | tr -d ' ') 个"
    echo ""
    ls -t $REPORTS_DIR 2>/dev/null | head -3 | while read f; do
        echo "  $f"
        grep "判定:" "$REPORTS_DIR/$f" 2>/dev/null | sed 's/^/    /'
    done
}

# --- 报告 ---
report() {
    local F="$REPORTS_DIR/$1"
    [ -f "$F" ] && cat "$F" || echo "报告不存在: $1"
}

# --- 主入口 ---
[ $# -lt 1 ] && usage
CMD="$1"; shift
case "$CMD" in
    wrap)    wrap "$@" ;;
    check|nca) nca "$@" ;;
    status)  status ;;
    rollback) echo "回滚到: $1"; cat "$CHECKPOINTS_DIR/$1.json" 2>/dev/null ;;
    report)  report "$1" ;;
    *)       usage ;;
esac
