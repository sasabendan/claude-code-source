---
name: kb-rust v1 需求草稿
entry_type: experience
created: 2026-04-26T00:23:03.569465+00:00
updated: 2026-04-26T00:23:03.569465+00:00
tags: [kb-rust,v1,requirements,draft,R1-R10]
status: stable
---

# kb-rust v1 需求草稿

> 源文件：`kb-rust/archive/v1/REQUIREMENTS_V1.md`（原名 REQUIREMENTS_V2.md，v2 开发前产物）
> 建立：2026-04-25 18:51（早于 v2 开发 18:48）
> 说明：此文档由 v1 代码库复制而来，含 R1-R10 需求草稿，后被 v2/REQUIREMENTS_V2.md 取代

## v1 现状（锁定）

| 命令 | 状态 | 备注 |
|------|------|------|
| init | ✅ | 创建目录结构 + 空 .index.jsonl |
| add | ✅ | 生成 Markdown + 追加 .index.jsonl |
| list | ✅ | 按类型统计 |
| query | ✅ | 按类型查询 |
| search | ✅ | 名称/标签全文搜索（大小写不敏感） |
| rebuild | ✅ | 从 Markdown frontmatter 重建索引 |

## 需求草稿（R1-R10，v2 将实现）

| 需求 | 优先级 | 来源 | 状态 |
|------|--------|------|------|
| R1 工作流说明书 | P0 | A1/A2 | ⚠️ v2 已实现 |
| R2 人物/角色管理 | P1 | A1/A2 | ⚠️ v2 部分实现 |
| R3 剧情分解标准化 | P2 | A1/A2 | ❌ |
| R4 双链索引 | P1 | A1/A2 | ⚠️ v2 部分实现 |
| R5 反馈优化记录 | P2 | A1/A2 | ❌ |
| R6 Git 版本控制集成 | P3 | A1/A2 | ❌ |
| R7 Biji API 同步 | P1 | TASK_REQUIREMENTS.md | ⚠️ v2 stub |
| R8 项目隔离 | P0 | A1/A2 | ✅ v2 已实现 |
| R9 Auto-commit 提示 | P3 | A1/A2 | ❌ |
| R10 向量/Embedding 搜索 | P4 | SKILL.md | ❌ |

## 后续

- 完整需求文档见：`kb-rust/archive/v2/REQUIREMENTS_V2.md`（含 R11）
- 规格说明见：`kb-rust/archive/v2/SPEC.md`