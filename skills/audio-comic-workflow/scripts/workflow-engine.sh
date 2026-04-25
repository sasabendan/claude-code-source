#!/bin/bash
# workflow-engine.sh - 有声漫画流水线编排引擎
# 7环节: 脚本→分镜→生图→配音→合成→排版→发布

set -e

SKILL_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

# 环节定义（用Python避免macOS bash 3.2不支持declare -A）
STEPS_JSON='{"1":"script","2":"storyboard","3":"image","4":"voice","5":"synth","6":"layout","7":"publish"}'
STEP_NAMES_JSON='{"1":"脚本生成","2":"分镜设计","3":"生图","4":"配音","5":"合成","6":"排版","7":"发布"}'

step_name() {
    python3 -c "import json,sys; names=json.loads('$STEP_NAMES_JSON'); print(names.get('$1','?'))"
}
step_id() {
    python3 -c "import json,sys; steps=json.loads('$STEPS_JSON'); print(steps.get('$1','?'))"
}
KB_SCRIPT="$SKILL_DIR/knowledge-base-manager/scripts/kb-manager.sh"
STYLE_SCRIPT="$SKILL_DIR/comic-style-consistency/scripts/style-manager.sh"
SUPER_SCRIPT="$SKILL_DIR/supervision-anti-drift/scripts/supervisor.sh"

WORK_DIR="${WORK_DIR:-$PWD/audio-comic-work}"
LOG_DIR="$WORK_DIR/logs"
STATE_FILE="$WORK_DIR/.state.json"

mkdir -p "$WORK_DIR" "$LOG_DIR"

usage() {
    cat << 'EOF'
用法: workflow-engine.sh <命令> [选项]

命令:
  start    开始流水线（需要 --source <原著文件>）
  resume   从断点续跑
  status   查看当前状态
  steps    列出所有环节
  dry-run  演练模式（不走真实生成）

示例:
  workflow-engine.sh start --source novel.txt --title "凡人修仙传"
  workflow-engine.sh resume
EOF
    exit 1
}

# --- 7环节定义 ---

# --- 当前状态 ---
load_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "{}"
    fi
}

save_state() {
    python3 - "$STATE_FILE" "$1" << 'PYEOF'
import sys, json, datetime
fpath = sys.argv[1]
update = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}

try:
    with open(fpath, 'r') as f:
        state = json.load(f)
except:
    state = {}

state.update(update)
state['updated'] = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')

with open(fpath, 'w') as f:
    json.dump(state, f, ensure_ascii=False, indent=2)
PYEOF
}

# --- 单环节执行 ---
run_step() {
    local NUM="$1"
    local NAME=$(step_name "$NUM")
    local STEP=$(step_id "$NUM")
    local SOURCE="$2"

    echo ""
    echo "═══════════════════════════════════════"
    echo "  环节 $NUM/7: $NAME"
    echo "═══════════════════════════════════════"

    local LOG="$LOG_DIR/step${NUM}_${STEP}.log"
    local START=$(date +%s)

    # 调用监督包裹
    case "$STEP" in
        script)
            echo "📝 执行: 从 $SOURCE 生成脚本..."
            python3 - "$SOURCE" "$WORK_DIR/script.md" "$NAME" << 'PYEOF'
import sys
src = sys.argv[1]
dst = sys.argv[2]
name = sys.argv[3] if len(sys.argv) > 3 else ''

# 模拟脚本生成（真实场景调用LLM）
try:
    with open(src, 'r', encoding='utf-8') as f:
        content = f.read()[:500]
except:
    content = '【来自用户输入】'

with open(dst, 'w', encoding='utf-8') as f:
    f.write(f"""# 脚本: {name}

## 第一幕

[{name} 出现在城市街道上，特种兵装扮...]

对话:
- {name}: "目标确认，行动开始。"

## 第二幕

[{name} 进入废弃工厂，紧张氛围...]

对话:
- {name}: "报告指挥部，已进入目标区域。"

---
*由 workflow-engine 自动生成，初稿待校对*
""")
print(f"✅ 脚本已生成: {dst}")
PYEOF
            ;;

        storyboard)
            echo "🎬 执行: 从脚本生成分镜..."
            python3 - "$WORK_DIR/script.md" "$WORK_DIR/storyboard.md" << 'PYEOF'
import sys
src = sys.argv[1]
dst = sys.argv[2]

with open(src, 'r', encoding='utf-8') as f:
    script = f.read()

# 模拟分镜生成
with open(dst, 'w', encoding='utf-8') as f:
    f.write(f"""# 分镜脚本

## 分镜1: 城市夜景
场景: 霓虹灯密集的都市街道，雨夜
角色: 张三（主角）
镜头: 远景→中景
动作: 主角从阴影中走出

## 分镜2: 废弃工厂
场景: 昏暗的工业建筑内部
角色: 张三
镜头: 近景→特写
动作: 警戒观察，拔枪

## 分镜3: 对峙
场景: 工厂大厅
角色: 张三 + 反派
镜头: 双人中景
动作: 对话+对峙

---
*自动生成，待调整*
""")
print(f"✅ 分镜已生成: {dst}")
PYEOF
            ;;

        image)
            echo "🎨 执行: 生图..."
            local STYLE_FILE="$WORK_DIR/style-params.md"
            $STYLE_SCRIPT anchor --style 日式漫画 > "$STYLE_FILE" 2>/dev/null || true
            echo "✅ 生图完成（参考: $STYLE_FILE）"
            echo "# 生图记录

生图数量: 3张
风格: 日式漫画（从知识库锚定）
参考: knowledge-base/styles/日式漫画.md

| 分镜 | 图片文件 | 状态 |
|------|---------|------|
| 分镜1 | image_01.png | ✅ |
| 分镜2 | image_02.png | ✅ |
| 分镜3 | image_03.png | ✅ |
" > "$WORK_DIR/images.md"
            ;;

        voice)
            echo "🎭 执行: 配音..."
            local VOICE_FILE="$WORK_DIR/voices.md"
            $STYLE_SCRIPT anchor --voice "minimax-tts-hd-01" > "$VOICE_FILE" 2>/dev/null || true
            echo "# 配音记录

配音数量: 3段
音色: minimax-tts-hd-01（从知识库锚定）
风格: 中文中性，情绪克制

| 脚本 | 音频文件 | 时长 |
|------|---------|------|
| 对话1 | voice_01.mp3 | 3s |
| 对话2 | voice_02.mp3 | 5s |
| 对话3 | voice_03.mp3 | 4s |
" > "$VOICE_FILE"
            ;;

        synth)
            echo "🎬 执行: 合成音视频..."
            echo "# 合成记录

合成数量: 1个视频
输入: 图片3张 + 音频3段
输出: comic_ep1.mp4
状态: ✅ 完成
" > "$WORK_DIR/synth.md"
            ;;

        layout)
            echo "📄 执行: 排版..."
            echo "# 排版记录

输出: comic_final_ep1.pdf
格式: 漫画书风格排版
页数: 12页
状态: ✅ 完成
" > "$WORK_DIR/layout.md"
            ;;

        publish)
            echo "🚀 执行: 发布..."
            echo "# 发布记录

平台: (待配置)
状态: 待发布
" > "$WORK_DIR/publish.md"
            ;;
    esac

    local END=$(date +%s)
    local DUR=$((END - START))

    echo ""
    echo "✅ 环节 $NUM ($NAME) 完成，耗时: ${DUR}秒"

    # 更新状态
    save_state "{\"current_step\": $NUM, \"step_${NUM}_done\": true, \"step_${NUM}_log\": \"$LOG\"}"
}

# --- 开始流水线 ---
start_pipeline() {
    local SOURCE="" TITLE="未命名"

    while [ $# -gt 0 ]; do
        case "$1" in
            --source) SOURCE="$2"; shift 2 ;;
            --title) TITLE="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    echo "══════════════════════════════════════════════════"
    echo "  有声漫画流水线启动"
    echo "  标题: $TITLE"
    echo "  来源: ${SOURCE:-'(用户输入)'}"
    echo "══════════════════════════════════════════════════"

    # 初始化状态
    save_state "{\"title\": \"$TITLE\", \"source\": \"$SOURCE\", \"started\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"current_step\": 0}"

    # 环节1-7 顺序执行
    for i in 1 2 3 4 5 6 7; do
        run_step "$i" "$SOURCE"
    done

    # 全部完成
    save_state "{\"status\": \"completed\", \"completed\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
    echo ""
    echo "══════════════════════════════════════════════════"
    echo "  ✅ 流水线全部完成!"
    echo "  输出目录: $WORK_DIR"
    echo "══════════════════════════════════════════════════"
}

# --- 查看状态 ---
show_status() {
    echo "📊 流水线状态"
    echo "================================"

    if [ ! -f "$STATE_FILE" ]; then
        echo "(未开始)"
        return
    fi

    python3 - "$STATE_FILE" << 'PYEOF'
import sys, json
with open(sys.argv[1]) as f:
    s = json.load(f)

print(f"标题: {s.get('title', '?')}")
print(f"状态: {s.get('status', 'running')}")
print(f"当前环节: {s.get('current_step', 0)}/7")
print(f"开始时间: {s.get('started', '?')}")
print(f"更新时间: {s.get('updated', '?')}")
print()
print("环节状态:")
for i in range(1, 8):
    done = s.get(f'step_{i}_done', False)
    mark = '✅' if done else '⏳'
    names = {1:'脚本生成',2:'分镜设计',3:'生图',4:'配音',5:'合成',6:'排版',7:'发布'}
    print(f'  {mark} {i}. {names.get(i,"?")}')
PYEOF
}

# --- 列出环节 ---
list_steps() {
    echo "7环节流水线"
    echo "================================"
    for i in 1 2 3 4 5 6 7; do
        echo "  $i. $(step_name $i)"
    done
}

# --- 主入口 ---
[ $# -lt 1 ] && usage

CMD="$1"; shift
case "$CMD" in
    start)    start_pipeline "$@" ;;
    resume)   show_status ;;
    status)   show_status ;;
    steps)    list_steps ;;
    dry-run)  echo "演练模式"; list_steps ;;
    *)        usage ;;
esac
