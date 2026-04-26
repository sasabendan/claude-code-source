---
name: kb-rust v2 需求文档
entry_type: experience
created: 2026-04-25T23:59:05.324588+00:00
updated: 2026-04-25T23:59:05.324588+00:00
tags: [kb-rust,v2,requirements,R1-R11]
status: stable
---

# kb-rust v2 需求文档

> 源文件：`kb-rust/v2/REQUIREMENTS_V2.md`
> 版本：v2.1.0 | 建立：2026-04-25

## 需求汇总（R1-R11）

| 需求 | 优先级 | 状态 | 说明 |
|------|--------|------|------|
| R1 工作流说明书 | P0 | ✅ | WORKFLOW.md 中央大脑 |
| R2 人物/角色管理 | P1 | ⚠️ 部分 | chars 命令 + status 字段 |
| R3 剧情分解标准化 | P2 | ❌ | plot-template 命令待实现 |
| R4 双链索引 | P1 | ⚠️ 部分 | rebuild 解析 [[wikilinks]]，backlinks 命令 |
| R5 反馈优化记录 | P2 | ❌ | _accepted/ + _rejected/ + yield-stats |
| R6 Git 版本控制集成 | P3 | ❌ | git-hint 命令 |
| R7 Biji API 同步 | P1 | ⚠️ stub | sync-biji（需 --features biji） |
| R8 项目隔离 | P0 | ✅ | .project.json + project-info |
| R9 Auto-commit 提示 | P3 | ❌ | backup-hint 命令 |
| R10 向量/Embedding 搜索 | P4 | ❌ | search-v 命令（v3 考虑） |
| R11 错误自动记录 | P1 | ❌ | fail-case 条目 → .index.jsonl |

## R11 态控设计（调试态/运行态）

- **调试态**（默认开启）：`KB_AUTO_LOG_ERRORS=1` 或 `--debug` → 错误追加 fail-case 条目到 .index.jsonl
- **运行态**（默认关闭）：无标志时仅 stderr，不污染 KB
- 原因：开发调试需要积累错误经验，但运行态不应污染用户知识库

## 命令完成度

- ✅ 12 命令：init / add / list / query / search / rebuild / workflow / chars / backlinks / ingest / lint / project-info
- ⚠️ 1 命令（stub）：sync-biji
- ❌ 3 命令：errors / yield-stats / git-hint

## 依赖

- walkdir / chrono / serde_json / serde_yaml / regex（均已引入）
- reqwest/tokio（可选，biji feature，默认不启用）


---

> **版本说明**：本条目为 `kb-rust/v2/REQUIREMENTS_V2.md` 的引用说明，版本历史以源文档为准。
