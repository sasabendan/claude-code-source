---
name: claude-cite-reference
entry_type: experience
created: 2026-04-26T00:40:15.000000+00:00
updated: 2026-04-26T00:40:15.000000+00:00
tags: [cite-reference,引用标记,@ref:,JSONL存储]
status: stable
---

# claude-cite-reference（引用标记）

> 保存并注入来自之前 Claude 回复的引用片段。
> 源码：`skills/claude-cite-reference/SKILL.md`

## 触发场景

- "quote this part" / "reference this answer"
- "引用这段" / "带入下一轮"
- "@ref:plan" / "cite ref:X"

## 存储位置

`.claude/refs.jsonl`（项目级）或 `~/.claude/refs.jsonl`（用户级）

## 四个操作

| 操作 | 命令 |
|------|------|
| 保存引用 | `python scripts/cite.py add --id plan --tags roadmap --stdin` |
| 列出引用 | `python scripts/cite.py list` |
| 显示引用 | `python scripts/cite.py show plan` |
| 删除引用 | `python scripts/cite.py delete plan` |

## @ref: 展开

当消息中包含 `@ref:plan,fix-1` 时，运行 `show --format block`，前置到工作上下文。
