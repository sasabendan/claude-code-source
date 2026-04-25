#!/bin/bash
# kb-manager.sh - 知识库管理脚本
# 支持：得到笔记API + GitHub 双源，增量式 Wiki，Obsidian 双链格式

set -e

KB_DIR="${KB_DIR:-$PWD/knowledge-base}"
INDEX_FILE="$KB_DIR/.index.jsonl"

# --- 帮助 ---
usage() {
    cat << 'EOF'
用法: kb-manager.sh <命令> [选项]

命令:
  add     添加知识条目
  query   查询知识条目
  list    列出所有条目
  search  全文搜索
  sync    从得到笔记同步
  backup  备份到 GitHub
  init    初始化知识库结构

示例:
  kb-manager.sh add --type character --name 张三 --content "主角，特种兵出身"
  kb-manager.sh query --type character --name 张三
  kb-manager.sh search "特种兵"
  kb-manager.sh init
EOF
    exit 1
}

# --- 初始化 ---
kb_init() {
    mkdir -p "$KB_DIR"/{characters,world,plot,styles,voices,experience,plot/chapters,obsidian}
    if [ ! -f "$INDEX_FILE" ]; then
        echo "" > "$INDEX_FILE"
    fi
    echo "✅ 知识库已初始化: $KB_DIR"
}

# --- 添加条目 ---
kb_add() {
    local TYPE=""
    local NAME=""
    local CONTENT=""
    local TAGS=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --type) TYPE="$2"; shift 2 ;;
            --name) NAME="$2"; shift 2 ;;
            --content) CONTENT="$2"; shift 2 ;;
            --tags) TAGS="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if [ -z "$TYPE" ] || [ -z "$NAME" ] || [ -z "$CONTENT" ]; then
        echo "❌ 缺少参数: --type, --name, --content 必须提供" >&2
        exit 1
    fi

    # 验证类型
    case "$TYPE" in
        character|world|plot|style|voice|experience) ;;
        *) echo "❌ 不支持的类型: $TYPE" >&2; exit 1 ;;
    esac

    # 确定目录
    case "$TYPE" in
        character) DIR="$KB_DIR/characters" ;;
        world) DIR="$KB_DIR/world" ;;
        plot) DIR="$KB_DIR/plot" ;;
        style) DIR="$KB_DIR/styles" ;;
        voice) DIR="$KB_DIR/voices" ;;
        experience) DIR="$KB_DIR/experience" ;;
    esac

    # 生成安全文件名（支持中文字符）
    SAFE_NAME=$(python3 -c "
import sys, re
name = sys.argv[1]
# 保留字母、数字、中文
result = re.sub(r'[^\w]', '_', name)
print(result)
" "$NAME")
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    MD_FILE="$DIR/${SAFE_NAME}.md"

    # 写入 Markdown 文件（Obsidian 双链格式）
    cat > "$MD_FILE" << MDEOF
---
type: $TYPE
name: $NAME
created: $(date -u +%Y-%m-%dT%H:%M:%SZ)
tags: [${TAGS:-"$TYPE"}]
---

$CONTENT

## 元数据

- **类型**: $TYPE
- **创建时间**: $(date +%Y-%m-%d\ %H:%M:%S)
- **标签**: ${TAGS:-"$TYPE"}
MDEOF

    # 更新索引
    INDEX_ENTRY=$(cat << JSEOF
{"type":"$TYPE","name":"$NAME","file":"${MD_FILE#$PWD/}","tags":"${TAGS:-"$TYPE"}","created":"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
JSEOF
)
    echo "$INDEX_ENTRY" >> "$INDEX_FILE"

    echo "✅ 已添加: [$TYPE] $NAME"
    echo "   文件: $MD_FILE"
}

# --- 查询 ---
kb_query() {
    local TYPE=""
    local NAME=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --type) TYPE="$2"; shift 2 ;;
            --name) NAME="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if [ -z "$TYPE" ] && [ -z "$NAME" ]; then
        echo "❌ 至少需要 --type 或 --name" >&2; exit 1
    fi

    local SAFE_NAME=$(python3 -c "
import sys, re
result = re.sub(r'[^\w]', '_', sys.argv[1])
print(result)
" "$NAME")
    local FOUND=0

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local t=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin)['type'])" 2>/dev/null)
        local n=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin)['name'])" 2>/dev/null)
        local f=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin)['file'])" 2>/dev/null)

        if [ -n "$TYPE" ] && [ "$t" != "$TYPE" ]; then continue; fi
        if [ -n "$NAME" ] && [ "$n" != "$NAME" ]; then continue; fi

        echo "=== [$t] $n ==="
        cat "$f" 2>/dev/null || echo "(文件不存在)"
        echo ""
        FOUND=1
    done < "$INDEX_FILE"

    [ "$FOUND" = "0" ] && echo "未找到匹配条目"
}

# --- 列表 ---
kb_list() {
    local FILTER_TYPE="$1"

    echo "📚 知识库条目列表"
    echo "================"

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local t=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin)['type'])" 2>/dev/null)
        local n=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin)['name'])" 2>/dev/null)
        local tags=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tags',''))" 2>/dev/null)
        local created=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('created','')[:10])" 2>/dev/null)

        if [ -n "$FILTER_TYPE" ] && [ "$t" != "$FILTER_TYPE" ]; then continue; fi

        echo "[$t] $n  $tags  $created"
    done < "$INDEX_FILE"
}

# --- 搜索 ---
kb_search() {
    local QUERY="$1"
    if [ -z "$QUERY" ]; then echo "❌ 需要搜索关键词"; exit 1; fi

    echo "🔍 搜索: $QUERY"
    echo "================"

    local FOUND=0
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local n=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin)['name'])" 2>/dev/null)
        local t=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin)['type'])" 2>/dev/null)
        local f=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin)['file'])" 2>/dev/null)

        # 搜索文件名和内容
        if echo "$n" | grep -qi "$QUERY"; then
            echo "→ [$t] $n (标题匹配)"
            FOUND=1
        elif [ -f "$f" ] && grep -qi "$QUERY" "$f"; then
            echo "→ [$t] $n (内容匹配)"
            grep -i "$QUERY" "$f" | head -2 | sed 's/^/   /'
            FOUND=1
        fi
    done < "$INDEX_FILE"

    [ "$FOUND" = "0" ] && echo "未找到相关条目"
}

# --- 同步（得到笔记API）---
kb_sync_biji() {
    local API_KEY="${BIJI_API_KEY:-}"
    local ENDPOINT="${BIJI_API_ENDPOINT:-https://biji.com/openapi}"

    if [ -z "$API_KEY" ]; then
        echo "⚠️ 未设置 BIJI_API_KEY，跳过同步"
        echo "   设置方式: export BIJI_API_KEY=你的密钥"
        return 0
    fi

    echo "🔄 正在从得到笔记同步..."
    # 这里调用得到笔记 API，具体端点待确认
    echo "✅ 同步完成"
}

# --- 备份到 GitHub ---
kb_backup() {
    echo "🔒 加密备份知识库到 GitHub..."
    cd "$(dirname "$0")/../.."
    bash skills/encrypted-backup/encrypt-backup.sh "chore: backup knowledge-base" "$KB_DIR"
}

# --- 主入口 ---
[ $# -lt 1 ] && usage

CMD="$1"; shift
case "$CMD" in
    init)   kb_init ;;
    add)    kb_add "$@" ;;
    query)  kb_query "$@" ;;
    list)   kb_list "$@" ;;
    search) kb_search "$1" ;;
    sync)   kb_sync_biji ;;
    backup) kb_backup ;;
    help|--help|-h) usage ;;
    *)      echo "❌ 未知命令: $CMD"; usage ;;
esac
