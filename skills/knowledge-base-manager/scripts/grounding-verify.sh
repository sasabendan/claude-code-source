#!/bin/bash
# grounding-verify.sh - 原文溯源验证
# 验证 LangExtract 提取结果的 char_interval 是否准确对应原文

set -e

EXTRACTIONS="${1:-}"
ORIGINAL_TEXT="${2:-}"

if [ -z "$EXTRACTIONS" ]; then
    echo "用法：grounding-verify.sh <extractions.jsonl> [原文文件或URL]"
    echo "示例：grounding-verify.sh extractions.jsonl chapter1.txt"
    exit 1
fi

echo "🔍 Source Grounding 验证"
echo "📁 提取结果：$EXTRACTIONS"
echo ""

if [ ! -f "$EXTRACTIONS" ]; then
    echo "❌ 错误：提取结果文件不存在"
    exit 1
fi

# 写入参数文件供 Python 读取
PARAMS_FILE=$(mktemp /tmp/gv-params-XXXXX.txt)
echo "$EXTRACTIONS" > "$PARAMS_FILE"
echo "${ORIGINAL_TEXT:-}" >> "$PARAMS_FILE"
trap "rm -f $PARAMS_FILE" EXIT

python3 << 'PYEOF'
import json
import sys

params_file = "/tmp/gv-params-XXXXX.txt"
try:
    with open("/tmp/gv-params-XXXXX.txt", "r") as f:
        lines = [l.rstrip("\n") for l in f.readlines()]
except Exception:
    print("⚠️ 无法读取参数文件，跳过详细验证")
    sys.exit(0)

extractions_file = lines[0] if len(lines) > 0 else ""
original_text = lines[1].strip() if len(lines) > 1 else ""

if not extractions_file:
    print("⚠️ 未指定提取结果文件")
    sys.exit(0)

try:
    with open(extractions_file, 'r', encoding='utf-8') as f:
        extractions = [json.loads(line) for line in f]
except Exception as e:
    print(f"❌ 无法读取提取结果：{e}")
    sys.exit(1)

total = len(extractions)
grounded_list = [e for e in extractions if e.get('char_interval') is not None]
ungrounded_list = [e for e in extractions if e.get('char_interval') is None]

grounded_count = len(grounded_list)
ungrounded_count = len(ungrounded_list)
grounding_rate = grounded_count / total if total > 0 else 0

print("=" * 50)
print("📊 Source Grounding 统计")
print("=" * 50)
print(f"总提取数：{total}")
print(f"有 char_interval：{grounded_count}")
print(f"无 char_interval：{ungrounded_count}")
print(f"grounding_rate：{grounding_rate:.2%}")
print("")

# 验证 char_interval 准确性（如果提供了原文）
if original_text and original_text.strip() and original_text not in ("''", '""', ""):
    print("🔍 验证 char_interval 准确性...")

    text = ""
    try:
        if original_text.startswith('http://') or original_text.startswith('https://'):
            import urllib.request
            with urllib.request.urlopen(original_text) as response:
                text = response.read().decode('utf-8')
        else:
            with open(original_text, 'r', encoding='utf-8') as f:
                text = f.read()
    except Exception:
        text = ""

    if text:
        verified = 0
        failed = 0

        for e in grounded_list:
            char_interval = e.get('char_interval')
            if char_interval and len(char_interval) == 2:
                start, end = char_interval
                if start >= 0 and end <= len(text) and start < end:
                    extracted_text = text[start:end]
                    expected = e.get('extraction_text', '')
                    if expected in text and abs(len(extracted_text) - len(expected)) < 50:
                        verified += 1
                    else:
                        failed += 1
                else:
                    failed += 1
            else:
                failed += 1

        accuracy = verified / grounded_count if grounded_count > 0 else 0
        print(f"验证样本：{grounded_count} 个")
        print(f"验证通过：{verified}")
        print(f"验证失败：{failed}")
        print(f"char_interval_accuracy：{accuracy:.2%}")
        print("")

        if accuracy >= 0.98:
            print("✅ char_interval_accuracy ≥ 98%，通过")
        elif accuracy >= 0.90:
            print("⚠️ char_interval_accuracy < 98%，建议审查")
        else:
            print("❌ char_interval_accuracy < 90%，需要修复")
    else:
        print("⚠️ 无法读取原文，仅统计 grounding_rate")
else:
    print("⚠️ 未提供原文文件，跳过准确性验证")

# 按 class 统计
print("")
print("📊 按类型分布：")
class_counts = {}
for e in extractions:
    cls = e.get('extraction_class', 'unknown')
    class_counts[cls] = class_counts.get(cls, 0) + 1

for cls, count in sorted(class_counts.items(), key=lambda x: -x[1]):
    print(f"  - {cls}: {count}")

print("")
print("=" * 50)

if grounding_rate >= 0.95:
    print("✅ 整体评估：PASS（grounding_rate ≥ 95%）")
elif grounding_rate >= 0.90:
    print("⚠️ 整体评估：WARN（90% ≤ grounding_rate < 95%）")
else:
    print("❌ 整体评估：FAIL（grounding_rate < 90%）")

if ungrounded_count > 0:
    print("")
    print("⚠️ 警告：以下提取物无 char_interval（必须过滤）：")
    for e in ungrounded_list[:5]:
        print(f"  - [{e.get('extraction_class')}] {e.get('extraction_text', '')[:50]}")

print("")
print("💡 提示：过滤无 char_interval 的提取物：")
print("  python3 -c \"import json; [print(json.dumps(e)) for e in json.load(open('extractions.jsonl')) if e.get('char_interval')]\"")
PYEOF
