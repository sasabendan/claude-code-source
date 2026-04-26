# 有声漫画知识库工作流说明书

> AI 开工前必读。本文件定义本知识库的运作规范。
> 版本：1.0 | 更新：2026-04-26

## 项目概述

**目标**：有声漫画自动化生产，起点=原著小说，输出=有声漫画产品。
**核心场景**：来料加工，顺着原著的故事线、世界观、作品调性打磨剧本。

## 工具入口

- **知识库工具**：`kb-rust/v2/target/release/kb-rust-v2`
- **入口索引**：`[[_compiled/_index.md]]`
- **操作日志**：`[[_compiled/_log.md]]`
- **项目元数据**：`[[.project.json]]`

## 三层架构

| 层 | 目录 | 说明 |
|---|------|------|
| Layer 1 | `characters/` `world/` `plot/` `styles/` `voices/` `experience/` | 原始文件（不可变，AI 只读） |
| Layer 2 | `_compiled/` | AI 生成 Wiki（entities/concepts/synthesis） |
| Layer 3 | `WORKFLOW.md` + 各 Skill SKILL.md | 工作规范 |

## 三个核心操作

### Ingest（摄入）
1. 收到新源文件（PDF/TXT/MD 等）
2. 读取内容，提取关键信息
3. 更新/创建 `_compiled/` Wiki 页面
4. 更新 `_index.md`、`_log.md`、`_overview.md`

### Query（查询）
1. 读取 `_index.md` 找相关页面
2. 读相关 Wiki 页面
3. 综合回答（引用格式：`[1]`）
4. 有价值的答案归档为新 Wiki 页面
5. 更新 `_log.md`

### Lint（健康检查）
1. 运行 `kb-rust-v2 lint`
2. 检查：矛盾页面 / 孤立页面 / 缺失交叉引用 / 过时声明
3. 更新 `_log.md`

## 页面写作规范

- 每个 Wiki 页面必须有至少一个视觉元素（Mermaid / 表格）
- 每个事实声明必须标注来源（`[^1]: source.pdf, p.3`）
- **双链标准**：每页至少包含 2–5 个 `[[wikilinks]]` 链接到其他 Wiki 页面
- 来源文件在 frontmatter 的 `sources:` 字段记录

## 双链标准（最低要求）

为使知识图谱"生长"出来，所有 KB 页面需遵守：

| 页面类型 | 最少双链数 | 说明 |
|---------|-----------|------|
| 角色页面 | ≥3 个 `[[...]]` | 链接到相关剧情/世界观/其他角色 |
| 剧情分解 | ≥2 个 `[[...]]` | 链接到角色/场景/其他章节 |
| 概念/经验 | ≥2 个 `[[...]]` | 链接到相关角色/剧情/参考文章 |
| 参考文章 | ≥1 个 `[[...]]` | 链接到相关概念或角色 |

> 逐步补链接后，Obsidian 图谱视图即可见知识网络。

## _log.md 格式

```
## [YYYY-MM-DD HH:MM:SS] <ingest|query|lint|add|rebuild|init> | <描述>
- 操作详情...
- 来源：xxx.md
- 关键发现：xxx
```

## 同步保证

- `add` / `ingest` 执行后自动触发 `rebuild`（_index.md 与 .index.jsonl 永远同步）
- `init` 对已有库为非破坏性补全（缺 .project.json / _log.md 头时补入，不覆盖已有内容）

## 安全约束

### 禁止自动删除（硬约束）
**开发过程中，所有主任务相关文件（即知识库管理的文件），不得自动请求删除。**
例外：User 主动明确要求删除。

违反后果（FC004）：核心资产文件（TASK_REQUIREMENTS.md / TASK_PROGRESS.md / master-plan.md）从本地消失，C11「本地明文永远保留」原则被破坏。

### C11 备份模型（不得误解）
- 本地 = 明文文件（永远保留，不加密）
- GitHub = `.enc` 加密文件（灾难恢复用）
- 两者是并行关系，不是替代关系
- 加密推送完成后，本地 .md 文件**不得删除**

## 参考文档

- [[kb-rust v2 规格说明书]] — kb-rust v2 完整规格
- [[kb-rust v2 需求文档]] — R1-R11 需求清单
- [[kb-rust v2 开发日志]] — 版本记录/Bug修复
- [[kb-rust 归档迁移记录]] — v1/v2 文件归档对照表
