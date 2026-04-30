#!/bin/bash
# constraints/scripts/pretool-check.sh
# PreToolUse Hook：版本历史检查 + 危险命令拦截 + 核心资产保护
# 触发时机：Edit/Write/Bash 工具执行前
# Exit 0: PASS，允许执行
# Exit 2: FAIL，阻止执行，显示错误

CONSTRAINTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="$(cd "$CONSTRAINTS_DIR/../.." && pwd)"

# 读取 stdin JSON
INPUT_JSON=$(cat)
if [ -z "$INPUT_JSON" ]; then
  exit 0
fi

# 解析 tool_name
TOOL_NAME=$(echo "$INPUT_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null || echo "")

# ─────────────────────────────────────────────
# P0：版本历史检查（Edit/Write 操作）
# ─────────────────────────────────────────────
if [[ "$TOOL_NAME" == "Edit" || "$TOOL_NAME" == "Write" ]]; then
  # 解析 file_path
  FILE_PATH=$(echo "$INPUT_JSON" | python3 -c "
import sys,json
d=json.load(sys.stdin)
ti=d.get('tool_input',{})
if isinstance(ti,dict):
    print(ti.get('file_path',''))
" 2>/dev/null || echo "")

  if [[ -n "$FILE_PATH" && "$FILE_PATH" == *.md ]]; then
    # 排除目录
    if [[ "$FILE_PATH" != *"/_compiled/"* && "$FILE_PATH" != *"/_distillation/"* ]]; then
      # 检查是否包含版本历史
      if grep -q "版本历史\|## Changelog\|## Version History" "$FILE_PATH" 2>/dev/null; then
        OLD_STRING=$(echo "$INPUT_JSON" | python3 -c "
import sys,json
d=json.load(sys.stdin)
ti=d.get('tool_input',{})
if isinstance(ti,dict):
    old=ti.get('old_string','')
    if '## 版本历史' in old or '### v' in old:
        print('VERSION_BLOCK_DETECTED')
" 2>/dev/null || echo "")

        if [[ "$OLD_STRING" == "VERSION_BLOCK_DETECTED" ]]; then
          echo '❌ 版本历史检查失败：禁止修改版本历史块' >&2
          echo '❌ 原因：Edit 操作试图覆盖已有的版本历史内容' >&2
          echo '❌ 正确做法：追加新版本块，而非覆盖旧版本' >&2
          echo '❌ 提示：保留原有的 ## 版本历史 内容，在顶部追加新版本' >&2
          exit 2
        fi
      fi
    fi
  fi
fi

# ─────────────────────────────────────────────
# P1：危险命令拦截（Bash 操作）
# ─────────────────────────────────────────────
if [[ "$TOOL_NAME" == "Bash" ]]; then
  # 解析 command
  COMMAND=$(echo "$INPUT_JSON" | python3 -c "
import sys,json
d=json.load(sys.stdin)
ti=d.get('tool_input',{})
if isinstance(ti,dict):
    print(ti.get('command',''))
" 2>/dev/null || echo "")

  if [[ -z "$COMMAND" ]]; then
    exit 0
  fi

  # 危险命令模式检测
  DANGEROUS_PATTERNS=(
    "rm\s*-rf\s*/"                    # rm -rf /
    "rm\s*-rf\s*\.\."                 # rm -rf ..
    "rm\s*-rf\s*~/"                   # rm -rf ~/
    "\.env"                            # .env 文件操作
    "chmod\s+777"                      # chmod 777
    ">\s*/etc/"                        # 写 /etc
    ">\s*/root/"                       # 写 /root
    "git\s+push\s+--force"             # force push
    "git\s+push\s+-f"                  # force push variant
    "eval\s+\$"                        # eval $...
    ";\s*rm\s+"                        # ;rm
  )

  for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -Eiq "$pattern"; then
      echo "❌ 危险命令拦截：检测到禁止模式 '$pattern'" >&2
      echo "❌ 命令已拦截：$COMMAND" >&2
      echo "❌ 提示：若需执行危险操作，请使用 BashTool 的 dangerouslyDisableSandbox 参数（需用户明确授权）" >&2
      exit 2
    fi
  done

  # 核心资产保护：禁止 git clean / git reset --hard 波及核心目录
  CORE_PATTERNS=(
    "git\s+clean\s+-fd"               # git clean 未加 --dry-run 保护
    "git\s+reset\s+--hard"             # git reset --hard
  )

  for pattern in "${CORE_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -Eiq "$pattern"; then
      # 检查是否涉及核心目录
      if echo "$COMMAND" | grep -Eiq "tasks|skills|knowledge-base|constraints"; then
        echo "❌ 核心资产保护：检测到破坏性 Git 命令涉及核心目录" >&2
        echo "❌ 命令：$COMMAND" >&2
        echo "❌ 提示：git reset --hard / git clean 会永久丢失核心资产（任务书/知识库/Skills）" >&2
        exit 2
      fi
    fi
  done

  # HC-AP：禁止直接删除核心资产目录
  HC_AP_PATTERNS=(
    "rm\s+-rf\s+.*tasks/audio-comic-skills"     # 删除任务目录
    "rm\s+-rf\s+.*skills/[^/]+$"                  # 误删整个 skill 目录（无后续路径）
    "rm\s+-rf\s+.*knowledge-base"                # 删除知识库
    "rm\s+-rf\s+.*constraints"                   # 删除约束目录
  )

  for pattern in "${HC_AP_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -Eiq "$pattern"; then
      echo "❌ HC-AP 核心资产保护：禁止删除核心资产目录" >&2
      echo "❌ 命令：$COMMAND" >&2
      echo "❌ 核心资产：任务书 / Skills / 知识库 / 约束元数据库" >&2
      exit 2
    fi
  done

  # HC-API：禁止写入 .env（API Key 操作）
  if echo "$COMMAND" | grep -Eiq "\.env|\.AWS|\.AZURE|secrets|credentials"; then
    if echo "$COMMAND" | grep -Eiq ">\s*|echo\s+[^|]|tee\s+"; then
      echo "❌ HC-API API Key 安全约束：禁止写入密钥文件" >&2
      echo "❌ 命令：$COMMAND" >&2
      echo "❌ API Key 操作须用户明确授权（HC-API4）" >&2
      exit 2
    fi
  fi
fi

# ─────────────────────────────────────────────
# P1：核心资产存在性检查（涉及 git 操作时）
# ─────────────────────────────────────────────
if [[ "$TOOL_NAME" == "Bash" ]]; then
  COMMAND=$(echo "$INPUT_JSON" | python3 -c "
import sys,json
d=json.load(sys.stdin)
ti=d.get('tool_input',{})
if isinstance(ti,dict):
    print(ti.get('command',''))
" 2>/dev/null || echo "")

  if echo "$COMMAND" | grep -Eiq "git\s+(push|commit|add)"; then
    # 检查核心文件本地存在性（HC-AP1）
    CORE_FILES=(
      "$PROJECT_ROOT/tasks/audio-comic-skills/TASK_REQUIREMENTS.md"
      "$PROJECT_ROOT/tasks/audio-comic-skills/TASK_PROGRESS.md"
      "$PROJECT_ROOT/heartbeat-state.md"
    )
    for f in "${CORE_FILES[@]}"; do
      if [[ -f "$f" ]]; then
        : # 存在，通过
      else
        echo "❌ HC-AP1 警告：核心资产本地缺失但 Git 历史存在" >&2
        echo "❌ 缺失文件：$f" >&2
        echo "❌ 请先恢复文件再执行 push/commit" >&2
        # 不完全阻止，但警告（可降级为 exit 2 严格模式）
      fi
    done
  fi
fi

exit 0
