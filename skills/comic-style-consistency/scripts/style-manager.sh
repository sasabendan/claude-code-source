#!/bin/bash
# style-manager.sh - 风格锚定与一致性管理

set -e

STYLE_DIR="${STYLE_DIR:-$PWD/knowledge-base}"
REF_POOL="$STYLE_DIR/ref-pool"

usage() {
    cat << 'EOF'
用法: style-manager.sh <命令> [选项]
命令:
  anchor    锚定参数（读知识库）
  list      列出所有配置
  add-ref   添加参考描述
  voice-set 设置音色
  verify    验证一致性
EOF
    exit 1
}

# --- 锚定风格参数 ---
anchor() {
    local ETYPE="" ENAME=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --character|--scene|--style|--voice)
                ETYPE="${1#--}"
                ENAME="$2"
                shift 2
                ;;
            *) shift ;;
        esac
    done
    [ -z "$ENAME" ] && { echo "❌ 需要 --character/--scene/--style <名称>"; exit 1; }

    case "$ETYPE" in
        character) FILE="$STYLE_DIR/characters/$ENAME.md" ;;
        scene)     FILE="$STYLE_DIR/world/$ENAME.md" ;;
        style)     FILE="$STYLE_DIR/styles/$ENAME.md" ;;
        voice)     FILE="$STYLE_DIR/voices/$ENAME.md" ;;
        *)         FILE="" ;;
    esac

    if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
        echo "❌ 未找到: ${FILE:-未知}"
        echo "提示: 用 kb-manager.sh 添加知识库条目"
        exit 1
    fi

    echo "📌 锚定: [$ETYPE] $ENAME"
    echo ""
    cat "$FILE"
    echo ""
    echo "--- 参数提取 ---"
    python3 - "$FILE" "$ETYPE" << 'PYEOF'
import sys, re, json

def main():
    filepath = sys.argv[1]
    etype = sys.argv[2] if len(sys.argv) > 2 else ''
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    params = {}
    patterns = {
        '风格': r'风格[：:]\s*(.+)',
        '线条': r'线条[：:]\s*(.+)',
        '上色': r'上色[：:]\s*(.+)',
        '比例': r'比例[：:]\s*(.+)',
        '色调': r'色调[：:]\s*(.+)',
        '音色': r'音色[：:]\s*(.+)',
        '情感': r'情感[：:]\s*(.+)',
    }
    for key, pat in patterns.items():
        m = re.search(pat, content)
        if m:
            params[key] = m.group(1).strip()

    if params:
        print(json.dumps(params, ensure_ascii=False, indent=2))
    else:
        # 提取所有 key: value 对
        pairs = re.findall(r'([^：:\n]+)[：:](.+)', content)
        if pairs:
            print(json.dumps(dict((k.strip(), v.strip()) for k,v in pairs[:8]), ensure_ascii=False, indent=2))
        else:
            print('(无可提取的结构化参数)')

if __name__ == '__main__':
    main()
PYEOF
}

# --- 列表 ---
list_all() {
    echo "📚 风格配置总览"
    echo "================================"

    echo "🎨 画风:"
    ls "$STYLE_DIR/styles/"*.md 2>/dev/null | while read f; do
        echo "  $(basename "$f" .md)"
    done
    [ -z "$(ls "$STYLE_DIR/styles/"*.md 2>/dev/null)" ] && echo "  (空)"

    echo "🎭 音色:"
    ls "$STYLE_DIR/voices/"*.md 2>/dev/null | while read f; do
        vid=$(python3 - "$f" << 'PYEOF'
import sys, re
with open(sys.argv[1], encoding='utf-8') as f:
    m = re.search(r'voice_id:\s*(.+)', f.read())
    print(m.group(1).strip() if m else '?')
PYEOF
)
        echo "  $(basename "$f" .md) → $vid"
    done
    [ -z "$(ls "$STYLE_DIR/voices/"*.md 2>/dev/null)" ] && echo "  (空)"

    echo "📌 参考图池:"
    ls -d "$REF_POOL"/*/ 2>/dev/null | while read d; do
        cnt=$(ls "$d"*.md 2>/dev/null | wc -l | tr -d ' ')
        echo "  $(basename "$d") ($cnt 个)"
    done
}

# --- 添加参考 ---
add_ref() {
    local RTYPE="" RNAME="" RDESC="无描述"
    while [ $# -gt 0 ]; do
        case "$1" in
            --type) RTYPE="$2"; shift 2 ;;
            --name) RNAME="$2"; shift 2 ;;
            --desc) RDESC="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    [ -z "$RTYPE" ] || [ -z "$RNAME" ] && { echo "❌ 需要 --type 和 --name"; exit 1; }

    mkdir -p "$REF_POOL/$RTYPE"
    local FNAME="$REF_POOL/$RTYPE/${RNAME}.md"
    python3 - "$FNAME" "$RTYPE" "$RNAME" "$RDESC" << 'PYEOF'
import sys
fname = sys.argv[1]
rtype = sys.argv[2]
rname = sys.argv[3]
rdesc = sys.argv[4] if len(sys.argv) > 4 else ''
with open(fname, 'w', encoding='utf-8') as f:
    f.write(f"""---
type: {rtype}
name: {rname}
created: {__import__('datetime').datetime.now().strftime('%Y-%m-%d')}
---

{rdesc}
""")
PYEOF
    echo "✅ 参考已添加: $RTYPE/$RNAME → $FNAME"
}

# --- 设置音色 ---
voice_set() {
    local CHAR="" VID="" EMO="neutral"
    while [ $# -gt 0 ]; do
        case "$1" in
            --character) CHAR="$2"; shift 2 ;;
            --voice) VID="$2"; shift 2 ;;
            --emotion) EMO="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    [ -z "$CHAR" ] || [ -z "$VID" ] && { echo "❌ 需要 --character 和 --voice"; exit 1; }

    mkdir -p "$STYLE_DIR/voices"
    local VFILE="$STYLE_DIR/voices/${CHAR}.md"
    python3 - "$VFILE" "$CHAR" "$VID" "$EMO" << 'PYEOF'
import sys, datetime
vfile = sys.argv[1]
char = sys.argv[2]
vid = sys.argv[3]
emo = sys.argv[4] if len(sys.argv) > 4 else 'neutral'

templates = {
    'happy': [0.8, 0.9, 1.0],
    'sad': [0.3, 0.5, 0.7],
    'angry': [0.9, 0.7, 0.6],
    'neutral': [0.5, 0.5, 0.5],
}

emotions = '\n'.join(f'| {k} | {v} |' for k, v in templates.items())

with open(vfile, 'w', encoding='utf-8') as f:
    f.write(f"""---
type: voice
character: {char}
voice_id: {vid}
emotion: {emo}
created: {datetime.datetime.now().strftime('%Y-%m-%d')}
---

## 音色配置

- 角色: {char}
- 音色ID: {vid}
- 当前情感: {emo}

## 情感模板

| 情感 | 参数 |
|------|------|
{emotions}
""")
PYEOF
    echo "✅ 音色已设置: $CHAR → $VID"
    echo "   $VFILE"
}

# --- 验证一致性 ---
verify() {
    local GFILE="$1" STYLE="$2"
    [ -z "$GFILE" ] || [ -z "$STYLE" ] && { echo "❌ 需要 <生成文件> <风格名称>"; exit 1; }

    local SFILE="$STYLE_DIR/styles/${STYLE}.md"
    [ ! -f "$SFILE" ] && { echo "❌ 风格文件不存在: $SFILE"; exit 1; }

    python3 - "$GFILE" "$SFILE" << 'PYEOF'
import sys, re

gen_file = sys.argv[1]
style_file = sys.argv[2]

with open(style_file, 'r', encoding='utf-8') as f:
    content = f.read()

# 提取中文+英文关键词
keywords = re.findall(r'[\u4e00-\u9fa5a-zA-Z]{2,}', content)
kw_set = sorted(set(kw.lower() for kw in keywords))
total = len(kw_set)

if total == 0:
    print('⚠️ 无法提取关键词')
    sys.exit(1)

# 读取生成文件
try:
    with open(gen_file, 'r', encoding='utf-8') as f:
        gen_content = f.read().lower()
except:
    gen_content = gen_file.lower()  # 假设是字符串内容

matched = sum(1 for kw in kw_set if kw in gen_content)
score = round(matched / total, 3) if total > 0 else 0

print(f'匹配: {matched}/{total} ({score})')
if score >= 0.6:
    print(f'✅ 一致性通过 (≥0.6)')
else:
    print(f'⚠️ 一致性偏低 (<0.6)，建议检查')
    sys.exit(1)
PYEOF
}

# --- 主入口 ---
[ $# -lt 1 ] && usage
CMD="$1"; shift
case "$CMD" in
    anchor)    anchor "$@" ;;
    list)      list_all ;;
    add-ref)   add_ref "$@" ;;
    voice-set) voice_set "$@" ;;
    verify)    verify "$@" ;;
    *)         usage ;;
esac
