---
name: pdf-ingest
description: PDF 内容提取与知识库摄入。当用户说"读取 PDF"、"提取 PDF 内容"、"把 PDF 入库"、"分析 PDF"时触发。也用于有声漫画原著（PDF/EPUB/MOBI）摄入到知识库。Use when: "pdf"、"PDF"、"extract"、"摄入"、提及 PDF 文件路径。
---

# Skill: pdf-ingest（PDF 知识库摄入）

> 版本：1.0 | 创建：2026-04-26
> 依赖：pymupdf4llm（专用虚拟环境），pdfplumber（备用）

## 触发时机

**语言触发**：
- "读取 PDF"、"提取 PDF 内容"
- "把 PDF 入库"、"分析 PDF"
- 提及 `.pdf` 文件路径

**自动触发**：收到新 PDF 源文件时

## 依赖安装

```bash
# 专用虚拟环境（隔离，不污染项目）
uv venv ~/.claude/skills/pdf-ingest/.venv
uv pip install --python ~/.claude/skills/pdf-ingest/.venv/bin/python pymupdf pymupdf4llm
```

## 工具选择

| 场景 | 工具 | 原因 |
|------|------|------|
| **首选：全文 Markdown 提取** | `pymupdf4llm` | 保留格式（标题/表格/列表），直接入库 |
| 备用：文字提取 | `pdfplumber` | 简单文字页，无需格式保留 |
| 表格精确提取 | `pdfplumber` | `page.extract_tables()` |
| OCR 扫描 PDF | `pytesseract` + `pdf2image` | 需要额外安装 tesseract |

## 核心流程

### 方式一：pymupdf4llm（推荐）

```bash
VENV="$HOME/.claude/skills/pdf-ingest/.venv"
$VENV/bin/python << 'PYEOF'
import pymupdf4llm
md = pymupdf4llm.to_markdown("input.pdf")
with open("output.md", "w") as f:
    f.write(md)
PYEOF
```

输出：完整 Markdown，保留：
- `#` 标题层级
- `**粗体**` / `*斜体*`
- `| 表格 |` Markdown 格式
- `1. 有序列表` / `- 无序列表`
- `==> picture [x x] intentionally omitted <==`（图片占位）

### 方式二：pdfplumber（备用）

```bash
python3 << 'PYEOF'
import pdfplumber

with pdfplumber.open("input.pdf") as pdf:
    for i, page in enumerate(pdf.pages):
        text = page.extract_text()
        tables = page.extract_tables()
        print(f"Page {i+1}: {len(text)} chars, {len(tables)} tables")
PYEOF
```

## 缓存机制

```
PDF 路径 → 内容 hash → ~/.cache/pdf-ingest/<hash>/
首次：完整提取（慢）
后续：直接读缓存（快）
```

## 知识库摄入流程

```
① 收到 PDF
② 提取 Markdown（pymupdf4llm）
③ 写入 knowledge-base/reference-articles/<名称>.md
④ 追加到 .index.jsonl（kb-rust add 或 rebuild）
⑤ 关联已有条目（[[wikilinks]]）
```

## 输出格式

```yaml
skill: pdf-ingest
source: input.pdf
pages: 42
chars_extracted: 7905
output: knowledge-base/reference-articles/<name>.md
kb_entries_added: 1
```

## 参考文件

- [[Claude_Code_CLI_2026完全指南]] — 示例：有声漫画技能体系参考
- [[knowledge-base-manager]] — 摄入后的索引管理

---

## 版本历史

### v1.1 (2026-04-30)
- 补录版本历史规则（约束元数据库建设 #BR-002）
- 嵌入 version-history 约束：版本号只追加不覆盖

### v1.0 (2026-04-26)
- 初始版本：PDF摄入技能建立
