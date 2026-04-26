---
name: kb-rust 归档迁移记录
entry_type: experience
created: 2026-04-26T00:18:38.078345+00:00
updated: 2026-04-26T00:40:31.000000+00:00
tags: [kb-rust,archive,migration,v1,v2]
status: stable
---

# kb-rust 归档迁移记录

> 源文件：`~/.backup/audio-comic-skills/kb-rust/MIGRATION_REGISTRY.md`
> 更新：2026-04-26

## 归档原则

**备份在外，项目在内。** 归档文件放 `~/.backup/`，项目目录只保留当前版本。

## 归档结构

```
~/.backup/audio-comic-skills/kb-rust/   ← 备份根目录（项目外）
├── MIGRATION_REGISTRY.md                ← 完整迁移记录（本文档源）
├── v1/                                  # v1 版本快照
│   ├── main.rs / README.md / REQUIREMENTS_V1.md / Cargo.toml / Cargo.lock
└── v2/                                  # v2 版本快照
    ├── main.rs / SPEC.md / CHANGELOG.md / REQUIREMENTS_V2.md
    ├── default_workflow.md / Cargo.toml / Cargo.lock
    └── Cargo_v1.toml / main_v1.rs

tasks/.../kb-rust/                       ← 项目目录（仅当前版本）
├── v2/src/                             # v2 当前源码
├── v2/target/release/kb-rust-v2        # v2 当前二进制
└── v2/SPEC.md / CHANGELOG.md          # v2 当前文档
```

## 迁移记录

| 版本 | 归档路径 | KB 条目数 |
|------|---------|---------|
| v1 | `~/.backup/.../kb-rust/v1/`（5 文件） | 见下方 |
| v2 | `~/.backup/.../kb-rust/v2/`（10 文件） | 见下方 |
| Skills 全景图 | `knowledge-base/experience/` | 1 条 |
| Skills 文件 | `knowledge-base/`（18 条） | 18 条 |
| **KB 总条目** | — | **56 条** |

### kb-rust 项目文件（11 条）

| KB 条目 | 归档路径 |
|---------|---------|
| kb-rust v2 规格说明书 | `~/.backup/.../v2/SPEC.md` |
| kb-rust v2 需求文档 | `~/.backup/.../v2/REQUIREMENTS_V2.md` |
| kb-rust v2 开发日志 | `~/.backup/.../v2/CHANGELOG.md` |
| kb-rust 归档迁移记录 | `~/.backup/.../MIGRATION_REGISTRY.md` |
| kb-rust v1 使用说明 | `~/.backup/.../v1/README.md` |
| kb-rust v1 源码快照 | `~/.backup/.../v1/main.rs` |
| kb-rust v1 需求草稿 | `~/.backup/.../v1/REQUIREMENTS_V1.md` |
| kb-rust v1 配置 | `~/.backup/.../v1/Cargo.toml` |
| kb-rust v2 默认工作流模板 | `~/.backup/.../v2/default_workflow.md` |
| kb-rust v2 迁移备份 | `~/.backup/.../v2/main_v1.rs` |
| kb-rust 参考项目分析 | `kb-rust/REFERENCE_PROJECTS.md`（原地保留） |

## 文档管理规则

| 文档类型 | 存放位置 | 索引方式 |
|---------|---------|---------|
| 归档文件 | `~/.backup/audio-comic-skills/kb-rust/v<N>/` | KB 条目 |
| 当前版本源码 | `kb-rust/v2/src/` | git 管理 |
| 二进制 | `kb-rust/*/target/release/` | SKILL.md 引用 |
| Skills 文档 | `skills/<skill>/SKILL.md` | KB 条目（18 条） |

## 恢复命令

```bash
# 恢复 v2 SPEC.md
cp ~/.backup/audio-comic-skills/kb-rust/v2/SPEC.md \
   tasks/audio-comic-skills/kb-rust/v2/SPEC.md
```

## 相关条目

- [[有声漫画 Skills 全景图]] — 18 个 Skill 分类 + 约束体系 + 当前优先级
- [[kb-rust v2 规格说明书]] — v2.1.1 完整规格
