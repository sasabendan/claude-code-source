---
name: kb-rust v2 迁移备份（v1→v2）
entry_type: experience
created: 2026-04-26T00:23:03.595774+00:00
updated: 2026-04-26T00:23:03.595774+00:00
tags: [kb-rust,v2,migration,v1-backup,Cargo,source]
status: stable
---

# kb-rust v2 迁移备份（v1→v2）

> 源文件：`kb-rust/archive/v2/main_v1.rs` + `archive/v2/Cargo_v1.toml`
> 说明：v1→v2 迁移时的快照备份，保留用于版本对照

## 备份文件清单

| 文件 | 行数 | 说明 |
|------|------|------|
| `archive/v2/main_v1.rs` | 295 行 | v1 → v2 迁移时保存的原始 main.rs |
| `archive/v2/Cargo_v1.toml` | 16 行 | v1 → v2 迁移时保存的原始 Cargo.toml |

## v1 → v2 主要变更

### 架构变更
- 单层 → 三层架构（Raw Sources / Wiki / Schema）
- 新增 `.project.json` / `_backlinks.json` / `_compiled/`

### 依赖变更
```diff
- regex（无）
+ regex ✅（v2 新增：双链 [[wikilinks]] 解析）
+ reqwest/tokio ⚠️（可选，biji feature，默认不启用）
```

### 命令变更
- v1：6 命令（init/add/list/query/search/rebuild）
- v2 新增：workflow / chars / backlinks / ingest / lint / project-info

### 源码行数
- v1 main.rs：295 行
- v2 main.rs：678 行（含双链解析/_compiled 更新/新命令）

### v2 独有功能
- 双链解析：`[[wikilinks]]` → `_backlinks.json`
- 空 name 回退到文件名（修复 karpathy_llm_wiki_original.md 无法索引问题）
- `lint` 健康检查（孤立页面/bad entries/双链统计）

## 迁移时间线

| 时间 | 事件 |
|------|------|
| 2026-04-24 | v1 初始版本（295 行，6 命令） |
| 2026-04-25 18:20 | v2 开发开始（复制 v1 为 v2/main_v1.rs） |
| 2026-04-25 18:53 | v2.1.0 完成（678 行，14 命令，R11 需求文档） |
| 2026-04-26 00:23 | 文件归档（archive/v1/ + archive/v2/） |

## 相关链接
- [[kb-rust 归档迁移记录]]
- [[knowledge-base-manager]]
- [[kb-rust v2]]
