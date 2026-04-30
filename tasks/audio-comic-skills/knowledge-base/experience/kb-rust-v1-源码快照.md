---
name: kb-rust v1 源码快照
entry_type: experience
created: 2026-04-26T00:23:03.566459+00:00
updated: 2026-04-26T00:23:03.566459+00:00
tags: [kb-rust,v1,rust,source,snapshot,295行]
status: stable
---

# kb-rust v1 源码快照

> 源文件：`kb-rust/archive/v1/main.rs`（295 行）
> 快照时间：2026-04-26（归档时复制）

## v1 源码结构

```
// kb-rust v1: LLM Wiki Manager (MD + JSONL, no SQLite)
├── KbEntry struct         # entry_type / name / file / tags / created + extra
├── KbManager impl         # load_index / add_entry / search / list_by_type / rebuild_index
├── infer_type()           # 目录 → entry_type 映射（6 类）
├── extract_title()       # frontmatter name: > # 标题 > 空
├── extract_tags()         # YAML 数组或逗号分隔
├── extract_created()      # created: 行解析
├── sanitize_filename()    # 文件名清理（特殊字符 → _）
└── main() match cmd       # init / add / list / query / search / rebuild
```

## v1 命令实现（6 个）

| 命令 | 行号 | 说明 |
|------|------|------|
| init | 226 | 创建 6 子目录 + 空 .index.jsonl |
| add | 233 | 生成 MD 文件 + 追加索引 |
| list | 265 | 按类型统计（HashMap 聚合） |
| query | 271 | 按 entry_type 过滤 |
| search | 277 | 全文搜索（name + tags，大小写不敏感） |
| rebuild | 283 | 全量扫描 MD → 重写 .index.jsonl |

## v1 vs v2 主要差异

| 维度 | v1（295 行） | v2（678 行） |
|------|------------|------------|
| 双链解析 | ❌ | ✅ [[wikilinks]] → _backlinks.json |
| _compiled 更新 | ❌ | ✅ _index.md + _overview.md |
| 角色状态 | ❌ | ✅ status 字段（stable/wip/retired） |
| 空 name 回退 | ❌ | ✅ 文件名回退 |
| lint | ❌ | ✅ 健康检查 |
| workflow 命令 | ❌ | ✅ 输出工作流 |
| 项目元数据 | ❌ | ✅ .project.json |

## v1 源码（完整）

```rust
// kb-rust v1 源码 295 行，详见源文件 kb-rust/archive/v1/main.rs
// 本条目为快照摘要，源码请查阅归档路径
```

## 相关链接
- [[kb-rust 归档迁移记录]]
- [[knowledge-base-manager]]
- [[kb-rust v2]]
