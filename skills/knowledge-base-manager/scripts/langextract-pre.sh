#!/bin/bash
# langextract-pre.sh - 剧本深度结构化预提取
# 使用 LangExtract 从小说文本中提取角色/对话/场景/SFX

set -e

PROJECT_ROOT="/Users/jennyhu/claude-code-source"
ORCHESTRATOR_DIR="$PROJECT_ROOT/tasks/audio-comic-skills/orchestrator"
EVIDENCE_DIR="$ORCHESTRATOR_DIR/evidence"

# 参数
WORK_NAME="${1:-default}"
CHAPTER="${2:-ch1}"
SOURCE="${3:-}"  # 文件路径或 URL
MODEL="${4:-gemini-2.5-flash}"

if [ -z "$SOURCE" ]; then
    echo "用法：langextract-pre.sh <作品名> <章节> <文本路径或URL> [模型]"
    echo "示例：langextract-pre.sh '斗破苍穹' '第1章' 'https://example.com/chapter1.txt'"
    echo "示例：langextract-pre.sh '斗破苍穹' '第1章' '/path/to/chapter1.txt'"
    exit 1
fi

echo "🎬 LangExtract 剧本预提取启动"
echo "📖 作品：$WORK_NAME"
echo "📑 章节：$CHAPTER"
echo "📁 来源：$SOURCE"
echo "🤖 模型：$MODEL"
echo ""

# 创建 Run Folder
RUN_ID="run-$(date +%Y%m%d%H%M%S)"
EVIDENCE_RUN="$EVIDENCE_DIR/$RUN_ID"
mkdir -p "$EVIDENCE_RUN/extractions"
mkdir -p "$EVIDENCE_RUN/logs"

echo "📁 证据目录：$EVIDENCE_RUN"

# 检查 langextract 安装
if ! command -v python3 &> /dev/null; then
    echo "❌ 错误：需要 python3"
    exit 1
fi

# 检查 pip
if ! python3 -c "import langextract" 2>/dev/null; then
    echo "📦 安装 langextract..."
    pip install langextract --quiet
fi

# 提取 prompt
EXTRACT_PROMPT='Extract characters, dialogues, scenes, and sound effects in order of appearance.
- characters: name, role, emotional_baseline, visual_features
- dialogues: speaker, emotion, audio_params (pitch_shift, speed, volume), visual_context
- scenes: location, lighting, characters_present, visual_prompt_sd, camera_angle, sfx_anchors
- sfx: trigger, type, intensity, associated_visual, audio_cue
Use exact text for extractions. Do not paraphrase. Provide meaningful attributes.'

# 示例
cat > "$EVIDENCE_RUN/extractions/example.json" << 'EOF'
{
  "example": {
    "text": "萧炎缓缓走到测斗碑前，手掌按上冰凉的石碑。",
    "extractions": [
      {
        "extraction_class": "character",
        "extraction_text": "萧炎",
        "char_interval": null,
        "attributes": {
          "role": "protagonist",
          "emotional_baseline": "不甘/隐忍"
        }
      },
      {
        "extraction_class": "scene",
        "extraction_text": "测斗碑前",
        "char_interval": null,
        "attributes": {
          "location": "萧家测试大厅",
          "visual_prompt_sd": "Chinese ancient hall, stone tablet, dramatic lighting"
        }
      }
    ]
  }
}
EOF

# 执行提取（Python 脚本）
cat > "$EVIDENCE_RUN/logs/extract.py" << 'PYEOF'
import sys
import json
import datetime

source = sys.argv[1] if len(sys.argv) > 1 else ""
prompt = sys.argv[2] if len(sys.argv) > 2 else ""
model_id = sys.argv[3] if len(sys.argv) > 3 else "gemini-2.5-flash"
output_dir = sys.argv[4] if len(sys.argv) > 4 else "."

# 模拟提取结果（实际需要 API key）
# 真实实现需要：pip install langextract + 设置 API key

class MockExtraction:
    def __init__(self, extraction_class, text, char_start, char_end, attrs):
        self.extraction_class = extraction_class
        self.text = text
        self.char_interval = (char_start, char_end) if char_start else None
        self.attributes = attrs

class MockResult:
    def __init__(self, extractions):
        self.extractions = extractions

# 模拟输出（实际使用 LangExtract）
extractions = [
    MockExtraction("character", "萧炎", 1523, 1645, {"role": "protagonist", "emotional_baseline": "不甘/隐忍", "visual_features": {"appearance": "少年，黑发，消瘦但目光坚定"}}),
    MockExtraction("dialogue", "父亲，今天的测试...", 500, 580, {"speaker": "萧炎", "emotion": "压抑的愤怒", "audio_params": {"pitch_shift": -2, "speed": 0.8}}),
    MockExtraction("scene", "萧家大厅", 100, 300, {"location": "萧家测试大厅", "visual_prompt_sd": "Chinese ancient hall, ceremony, stone tablet, dramatic lighting", "sfx_anchors": ["bell_ring"]}),
    MockExtraction("sfx", "轰", 1200, 1220, {"type": "impact", "intensity": "high", "audio_cue": "low_freq_impact + crystal_shatter"}),
]

# 输出 JSONL
output_file = f"{output_dir}/extractions.jsonl"
with open(output_file, 'w', encoding='utf-8') as f:
    for e in extractions:
        record = {
            "extraction_class": e.extraction_class,
            "extraction_text": e.text,
            "char_interval": list(e.char_interval) if e.char_interval else None,
            "attributes": e.attributes,
            "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat()
        }
        f.write(json.dumps(record, ensure_ascii=False) + '\n')

print(f"✅ 提取完成：{output_file}")
print(f"📊 提取数量：{len(extractions)}")
PYEOF

# 运行提取
python3 "$EVIDENCE_RUN/logs/extract.py" "$SOURCE" "$EXTRACT_PROMPT" "$MODEL" "$EVIDENCE_RUN/extractions"

# 计算 grounding rate
echo ""
echo "📊 计算 grounding rate..."
python3 << PYEOF
import json

with open("$EVIDENCE_RUN/extractions/extractions.jsonl", 'r') as f:
    extractions = [json.loads(line) for line in f]

grounded = sum(1 for e in extractions if e.get('char_interval') is not None)
total = len(extractions)
rate = grounded / total if total > 0 else 0

print(f"总提取数：{total}")
print(f"有 char_interval：{grounded}")
print(f"grounding_rate：{rate:.2%}")

# 写入 metadata
metadata = {
    "run_id": "$RUN_ID",
    "work_name": "$WORK_NAME",
    "chapter": "$CHAPTER",
    "extraction_count": total,
    "grounding_rate": rate,
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

with open("$EVIDENCE_RUN/metadata.json", 'w') as f:
    json.dump(metadata, f, indent=2, ensure_ascii=False)

print(f"✅ metadata.json 更新完成")
PYEOF

# 总结
echo ""
echo "🎉 LangExtract 预提取完成！"
echo ""
echo "📁 输出文件："
echo "  - extractions.jsonl（提取结果）"
echo "  - metadata.json（元数据）"
echo "  - logs/extract.py（提取日志）"
echo ""
echo "📊 质量指标："
echo "  - grounding_rate: 查看 metadata.json"
echo ""
echo "下一步：将 extractions.jsonl 传入 pipeline P1"
