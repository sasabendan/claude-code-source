---
name: kb-rust 参考项目分析
entry_type: experience
created: 2026-04-25T23:59:05.336893+00:00
updated: 2026-04-25T23:59:05.336893+00:00
tags: [kb-rust,karpathy,nashsu,lucasastorian]
status: stable
---

# kb-rust 参考项目分析

> 源文件：`kb-rust/REFERENCE_PROJECTS.md`（v1 建立）+ `kb-rust/v2/SPEC.md` 参考来源章节

## 设计谱系（从源头到实现）

```
Karpathy llm-wiki（origin，桌面 /Users/jennyhu/Desktop/llmwiki.md 为 canonical 原版）
    ├── nashsu/llm_wiki（purpose.md 对应 WORKFLOW.md / 两步思维链 / 增量缓存）
    └── lucasastorian/llmwiki（MCP 工具设计 / 写作规范：视觉元素+引用）
```

## 三大参考来源

| 项目 | 核心贡献 | kb-rust v2 对应 |
|------|---------|----------------|
| Karpathy llm-wiki | 三层架构（Raw/Wiki/Schema）/ Ingest-Query-Lint / index.md+log.md | 全部采纳（v2 核心设计） |
| nashsu/llm_wiki | purpose.md（WORKFLOW.md 对应）/ 两步思维链 | WORKFLOW.md + workflow 命令 |
| lucasastorian/llmwiki | MCP 工具规范 / 写作规范 | [[wikilinks]] 双链 + rebuild 双链解析 |

## A1/A2 微信参考文章（小李飞刀案例）

- 起点：原著 PDF，AI 逐步理解创作标准
- 反馈优化：第一回良品率 50% → 第四回 70%
- 工作流说明书.md 作为中央大脑
- Git 版本控制：10分钟自动备份

## GitHub Stars 参考

| 仓库 | ⭐ | 对应需求 | 状态 |
|------|---|---------|------|
| Astro-Han/karpathy-llm-wiki | 605 | S1 LLM Wiki | ✅ 已参考（桌面 canonical 原版更权威） |
| eugeniughelbur/obsidian-second-brain | 271 | S1/S6 Obsidian | SKILL.md 引用 |
| JimLiu/baoyu-skills | 16,273 | S2/S3/S6 | ✅ 已抓取（baoyu_skills_full.md） |

## TASK_REQUIREMENTS.md Skill 1 设计要求

- 得到笔记 OpenAPI + GitHub 双源
- 增量式 Wiki 架构（非传统 RAG）
- Obsidian 双链格式支持

