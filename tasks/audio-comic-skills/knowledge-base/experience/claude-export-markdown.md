---
name: claude-export-markdown
entry_type: experience
created: 2026-04-26T00:40:15.000000+00:00
updated: 2026-04-26T00:40:15.000000+00:00
tags: [export-markdown,Claude回复导出,remote-images,frontmatter]
status: stable
---

# claude-export-markdown（Claude 回复导出）

> 将 Claude 回复导出为自包含的 Markdown 文件。
> 源码：`skills/claude-export-markdown/SKILL.md`

## 触发场景

- "export this reply" / "save as markdown"
- "导出这条回复" / "转成 md"
- 提供 `.jsonl` 文件要求导出

## 核心原则

- 图像保留为远程 URL（不下载，不 base64）
- frontmatter 记录 `exported_at` / `source` / `session_id` / `model`
- 单文件自包含

## CLI 用法

```bash
# 从原始文本
python scripts/export_reply.py --from-text --input reply.txt --output reply.md

# 从 jsonl 会话文件
python scripts/export_reply.py --from-jsonl --input session.jsonl --output reply.md

# 指定消息索引
python scripts/export_reply.py --from-jsonl --input session.jsonl --index 3 --output reply.md
```

## 与其他 Skill 的关系

- [[claude-cite-reference]]：引用标记（不导出整个对话）
