# 有声漫画知识库工作流说明书

> AI 开工前必读。本文件定义本知识库的运作规范。

## 项目概述

**目标**：有声漫画自动化生产，起点=原著小说，输出=有声漫画产品。
**核心场景**：来料加工，顺着原著的故事线、世界观、作品调性打磨剧本。

## 三层架构

| 层 | 目录 | 说明 |
|---|------|------|
| Layer 1 | `characters/` `world/` `plot/` `styles/` `voices/` `experience/` | 原始文件（不可变，AI 只读） |
| Layer 2 | `_compiled/` | AI 生成 Wiki（entities/concepts/synthesis） |
| Layer 3 | `WORKFLOW.md` + 各 Skill SKILL.md | 工作规范 |

## 三个核心操作

### Ingest（摄入）
1. 收到新源文件
2. 读取内容，提取关键信息
3. 更新/创建 `_compiled/` Wiki 页面
4. 更新 `_index.md`、`_log.md`、`_overview.md`

### Query（查询）
1. 读取 `_index.md` 找相关页面
2. 读相关 Wiki 页面
3. 综合回答（引用格式：[1]）
4. 有价值的答案归档为新 Wiki 页面
5. 更新 `_log.md`

### Lint（健康检查）
检查：矛盾页面 / 孤立页面 / 缺失交叉引用 / 过时声明
更新 `_log.md`

## 页面写作规范

- 每个 Wiki 页面必须有至少一个视觉元素（Mermaid / 表格）
- 每个事实声明必须标注来源（`[^1]: source.pdf, p.3`）
- 使用 `[[wikilinks]]` 链接其他 Wiki 页面
- 来源文件在 frontmatter 的 `sources:` 字段记录

## _log.md 格式

```
## [YYYY-MM-DD HH:MM:SS] <ingest|query|lint> | <描述>
- 操作详情...
- 来源：xxx.md
- 关键发现：xxx
```
