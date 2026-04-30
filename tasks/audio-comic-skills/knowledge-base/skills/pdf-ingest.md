---
name: pdf-ingest
entry_type: skills
created: 2026-04-26T00:00:00.000000+00:00
updated: 2026-04-26T00:00:00.000000+00:00
tags: [pdf-ingest,PDF,extract,pymupdf4llm,知识库摄入]
status: stable
---

# pdf-ingest（PDF 知识库摄入）

> 源码：`skills/pdf-ingest/SKILL.md`
> 版本：1.0 | 创建：2026-04-26

## 定位

**工具技能（Utility Skill）**——PDF 内容提取与知识库摄入。
隶属于 [[knowledge-base-manager]] 增量 Wiki 体系。

## 核心能力

| 能力 | 说明 |
|------|------|
| PDF 文本提取 | pymupdf4llm 全内容 Markdown 转换 |
| 备用提取 | pdfplumber 表格/布局保留 |
| 缓存机制 | `~/.cache/pdf-ingest/<hash>/` 避免重复处理 |
| KB 入库 | 提取后写入 `reference-articles/` + 触发 KB rebuild |

## 工具选择

| 场景 | 工具 | 原因 |
|------|------|------|
| 首选 | `pymupdf4llm.to_markdown()` | 完整 Markdown 输出（含结构化标题） |
| 备用 | `pdfplumber` | 表格/布局敏感内容 |

## 依赖安装

```bash
uv venv ~/.claude/skills/pdf-ingest/.venv
uv pip install --python ~/.claude/skills/pdf-ingest/.venv/bin/python pymupdf pymupdf4llm
```

## 典型工作流

```
1. 用户提供 PDF 路径
2. 计算 hash → 检查 ~/.cache/pdf-ingest/<hash>/
3. 缓存命中 → 直接返回缓存内容
4. 缓存未命中 → pymupdf4llm.to_markdown() 提取
5. 写入 knowledge-base/reference-articles/<name>.md
6. 追加 KB 条目到 .index.jsonl
7. 通知用户：可直接 @ref:<name> 引用
```

## 与其他 Skill 的关系

- [[knowledge-base-manager]]：主管，pdf-ingest 是其执行组件
- [[encrypted-backup]]：PDF 摄入 KB 后，可触发加密备份
- [[audio-comic-workflow]]：原著（PDF/EPUB/MOBI）摄入知识库是 S1 输入环节

## 版本历史

### v1.0 (2026-04-26)
- 初始版本：从 Get笔记 两篇 Claude Code PDF 提取实践总结
- 工具选型：pymupdf4llm（主）+ pdfplumber（备）
- 缓存机制：hash 路径避免重复处理
- 产出：Claude Code CLI 2026完全指南.md、Claude Code 扩展类型深度解析.md
