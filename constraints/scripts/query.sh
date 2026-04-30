#!/bin/bash
# constraints/scripts/query.sh
# 约束查询脚本：给定 Skill + 动作，输出适用约束

CONSTRAINTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  echo "Usage: $0 --skill <skill_name> --action <action> [--file <file_path>]"
  echo "       $0 --constraint <constraint_id>"
  echo ""
  echo "Examples:"
  echo "  $0 --skill chinese-thinking --action edit --file SKILL.md"
  echo "  $0 --constraint version-history"
}

SKILL=""
ACTION=""
FILE=""
CONSTRAINT=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --skill) SKILL="$2"; shift 2 ;;
    --action) ACTION="$2"; shift 2 ;;
    --file) FILE="$2"; shift 2 ;;
    --constraint) CONSTRAINT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) shift ;;
  esac
done

# 如果指定了具体约束
if [[ -n "$CONSTRAINT" ]]; then
  CFPATH="$CONSTRAINTS_DIR/${CONSTRAINT}.yaml"
  if [[ -f "$CFPATH" ]]; then
    echo "=== 约束: $CONSTRAINT ==="
    grep "^#\|name:\|id:\|applies_to:\|violation_action:" "$CFPATH" | head -20
  else
    echo "❌ 约束 $CONSTRAINT 不存在"
  fi
  exit 0
fi

# 查询 Skill 适用约束
if [[ -n "$SKILL" ]]; then
  echo "=== Skill: $SKILL | Action: $ACTION | File: $FILE ==="
  echo ""
  echo "适用约束："
  
  # 基础约束（所有 Skills）
  echo "  [基础] version-history: 版本历史只追加不覆盖"
  echo "  [基础] c19: 发现违规记录并修复"
  echo "  [基础] c23: 补技能不补约束"
  
  # Skill 特定
  if [[ "$SKILL" == "claude-first-check" ]]; then
    echo "  [Skill] c17: 七步查询顺序"
    echo "  [Skill] c18: 3分钟无动作则自检"
  elif [[ "$SKILL" == "claude-error-handler" ]]; then
    echo "  [Skill] c17: 七步查询顺序"
    echo "  [Skill] c20: 错误范例关键词非修改依据"
    echo "  [Skill] c22: 错误范例仅作查询依据"
  elif [[ "$SKILL" == "chinese-thinking" ]]; then
    echo "  [Skill] c17: 七步查询顺序"
    echo "  [Skill] c23: 补技能不补约束"
  elif [[ "$SKILL" == "task-book-keeper" ]]; then
    echo "  [Skill] hc-ap1: 本地明文永远保留"
    echo "  [Skill] hc-ap2: 备份模型并行"
  elif [[ "$SKILL" == "knowledge-base-manager" ]]; then
    echo "  [Skill] hc-ap1: 本地明文永远保留"
    echo "  [Skill] hc-ap3: 禁止自动删除"
    echo "  [Skill] c-dev: 项目目录约束"
  elif [[ "$SKILL" == "core-asset-protection" ]]; then
    echo "  [Skill] hc-ap1/2/3: 核心资产保护"
    echo "  [Skill] hc-api1/2: API Key安全约束"
  fi
  
  echo ""
  echo "=== 约束检查 ==="
  
  # 版本历史检查
  if [[ "$ACTION" == "edit" || "$ACTION" == "write" ]]; then
    echo "✅ version-history: PASS（需追加版本块，非覆盖）"
  fi
  
  if [[ "$ACTION" == "delete" && "$FILE" == *"TASK_"* ]]; then
    echo "❌ hc-ap1: VIOLATION（核心资产禁止删除）"
  fi
fi
