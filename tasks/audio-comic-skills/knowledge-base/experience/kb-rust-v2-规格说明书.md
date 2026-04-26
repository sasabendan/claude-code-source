---
name: kb-rust v2 规格说明书
entry_type: experience
created: 2026-04-25T23:59:05.317626+00:00
updated: 2026-04-25T23:59:05.317626+00:00
tags: [kb-rust,v2,spec,三层架构,Ingest-Query-Lint]
status: stable
---

# kb-rust v2 规格说明书

> 源文件：`kb-rust/v2/SPEC.md`
> 版本：v2.1-draft | 更新：2026-04-25

## 核心理念

LLM Wiki ≠ 传统 RAG。传统 RAG 每次重新检索，无积累；LLM Wiki 是持久复合产物，跨文档综合、交叉引用、矛盾标记，知识编译一次持续更新。

## 三层架构

| 层 | 内容 | 说明 |
|---|------|------|
| Layer 1: Raw Sources | characters/ world/ plot/ styles/ voices/ experience/ | 原始文件，AI 只读不写，source of truth |
| Layer 2: Wiki | _compiled/（entities/ concepts/ synthesis/） | AI 生成和维护，_index.md + _log.md + _overview.md |
| Layer 3: Schema | WORKFLOW.md + SKILL.md | 告诉 AI 如何运作 |

## v2 命令（已实现）

- `init` 初始化目录（含 _compiled/ + .project.json）
- `add` 添加条目（含 updated/status 字段）
- `list` / `query` / `search` 查询
- `rebuild` 重建索引 + 双链解析 + _compiled/ 更新
- `workflow` 输出 WORKFLOW.md
- `chars` 列出角色及状态（stable/wip/retired）
- `backlinks <target>` 查找指向 target 的文件
- `ingest <file>` 摄入源文件 → 更新 _log.md
- `lint` 健康检查（孤立页面/bad entries/总条目/双链统计）
- `project-info` 输出 .project.json

## 已知限制（L1-L4）

- L1：ingest 仅支持 .md（未来支持 .txt/.pdf/.epub/.docx）
- L2：非标准 MD 文件自动回退到文件名作为 name
- L3：search 全量文本扫描，>10000 条性能下降
- L4：rebuild 依赖文件存在，文件删除后索引不自动更新

## 参考来源

- Karpathy llm-wiki（桌面 llmwiki.md 为 canonical 原版）
- nashsu/llm_wiki（purpose.md 对应 WORKFLOW.md）
- lucasastorian/llmwiki（MCP 工具设计）
- A1/A2（微信参考文章：小李飞刀案例）
- TASK_REQUIREMENTS.md（C19 → R11 错误自动记录）

