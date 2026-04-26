---
name: knowledge-base-manager
entry_type: skills
created: 2026-04-26T00:40:01.278552+00:00
updated: 2026-04-26T00:40:01.278552+00:00
tags: [知识库,增量Wiki,Obsidian,biji-API,S1]
status: stable
---

# knowledge-base-manager（知识库管理）

> 管理有声漫画生产的知识库，记录原著细节、世界观、角色设定。
> 源码：`skills/knowledge-base-manager/SKILL.md`

## 核心能力

| 能力 | 说明 |
|------|------|
| 双源数据 | 得到笔记 API [网络] + GitHub [备份] |
| 增量式 Wiki | 非传统 RAG，持久化知识积累 |
| Obsidian 双链 | [[双向链接]] 格式支持 |
| 版本管理 | Git 版本控制 |

## 当前实现

- [[audio-comic-workflow]]：工具入口为 [[kb-rust v2]]
- 工具路径：`kb-rust/v2/target/release/kb-rust-v2`
- 文档管理规则见 [[kb-rust 归档迁移记录]]

## 三层架构（v2 实现）

```
Layer 1: Raw Sources（characters/world/plot/styles/voices/experience）
Layer 2: _compiled/（entities/concepts/synthesis）
Layer 3: WORKFLOW.md + SKILL.md
```

## 与其他 Skill 的关系

- [[self-optimizing-yield]]：经验库使用 LLM Wiki 存储
- [[task-book-keeper]]：任务书加密备份依赖本技能
