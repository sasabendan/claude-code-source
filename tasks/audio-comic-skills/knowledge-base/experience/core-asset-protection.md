---
name: core-asset-protection
entry_type: experience
created: 2026-04-26T00:00:00.000000+00:00
updated: 2026-04-26T00:00:00.000000+00:00
tags: [core-asset,HC-AP1,HC-AP2,HC-AP3,FC004,备份模型,禁止删除]
status: stable
---

# core-asset-protection（核心资产保护）

> 源码：`skills/core-asset-protection/SKILL.md`
> 版本：1.0 | 创建：2026-04-26 | 来源：FC004 根因补救

## 定位

**工具技能（Utility Skill）**，负责核心资产的识别认定、备份模型执行、删除安全判定。

## 硬约束体系（HC-AP）

| 约束 | 内容 | 优先级 |
|------|------|--------|
| **HC-AP1** | 本地明文永远保留：核心资产本地 .md 不删除，GitHub 加密 .enc 是并行备份层 | 最高 |
| **HC-AP2** | 禁止自动请求删除：知识库管理的文件不得自动请求删除（User 主动要求除外） | 最高 |
| **HC-AP3** | 密码隔离存储：`~/.backup-password`（chmod 600），不推 GitHub，不备份 | 最高 |

## 核心资产范围

| 类型 | 文件 |
|------|------|
| 任务书 | `TASK_REQUIREMENTS.md` / `TASK_PROGRESS.md` / `master-plan.md` |
| 知识库 | `knowledge-base/` 下所有文件 |
| Skills | `skills/*/SKILL.md` |
| 参考文档 | `reference-*.md` / `reference-articles/` |
| 项目元数据 | `.project.json` / `CLAUDE.md` / `WRAP.md` |

## 备份模型（C11）

```
本地（明文 .md）←→ GitHub（加密 .enc）
       并行关系，非替代关系
```

**误解**：加密推送完成 = 本地文件可以删除
**正确**：加密推送完成 = GitHub 多了一层保护，本地文件原封不动

## FC004 根因

| 步骤 | 错误 | 正确 |
|------|------|------|
| ① 加密推送 GitHub | ✅ | ✅ |
| ② 删除本地 .md | ❌ | 本地永远保留 |
| ③ 未触发 C17 查询 | ❌ | 任何删除前必须先查任务书/知识库 |

**教训**：对「文件生命周期」的修改，必须 C17 查询。

## 与其他 Skill 的关系

- [[claude-file-safety]]：删除前判定，依赖本 Skill 的红灯清单
- [[encrypted-backup]]：执行加密备份，依赖本 Skill 的 HC-AP1
- [[task-book-keeper]]：任务书保护，核心资产子类
- [[knowledge-base-manager]]：知识库保护，核心资产子类
- [[claude-error-handler]]：FC004 记录在案
