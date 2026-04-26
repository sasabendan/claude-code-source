---
name: claude-file-safety
entry_type: experience
created: 2026-04-26T00:40:15.000000+00:00
updated: 2026-04-26T00:00:00.000000+00:00
tags: [file-safety,删除判定,主线相关性,红灯绿灯,禁止自动删除]
status: stable
---

# claude-file-safety（文件安全删除判定）

> 需要删除任何文件时，先判断主线任务相关性和上下文影响再决定。
> 源码：`skills/claude-file-safety/SKILL.md`

## 硬约束（禁止违反）

**开发过程中所有主任务相关文件，即知识库管理的文件，均不得自动请求删除。**
例外条件：User 主动明确要求删除。

> 来源：2026-04-26 用户硬约束（FC004 根因补救）

违反此约束的后果：TASK_REQUIREMENTS.md、TASK_PROGRESS.md、master-plan.md 三个核心资产文件从本地消失，破坏 C11「本地明文 + 版本管理」原则。所有文件从 GitHub 解密恢复。

## 判定流程

### 第一步：主线任务相关性检查

```
在以下任一出现 → 主线相关（红灯/谨慎）
  - TASK_REQUIREMENTS.md / TASK_PROGRESS.md / HEARTBEAT.md / CLAUDE.md / master-plan.md
  - knowledge-base/.index.jsonl 任意条目

在以下任一出现 → 主线相关（需额外确认）
  - git commit 历史
  - 其他 Skill SKILL.md 引用
```

### 第二步：上下文依赖检查

```
git grep "<文件名>" 检查所有引用
有引用 → 红灯，不删除
无引用 → 谨慎删除，先备份再删
```

## 红灯（禁止删除）

- 任务书体系内的任何文件
- 知识库条目指向的文件
- HEARTBEAT.md / heartbeat-state.md

## 绿灯（可直接删除）

- 不在任何体系内的文件
- 临时文件（*.tmp / *.bak / *.log）

## 与其他 Skill 的关系

- [[claude-scope-judge]]：范围判定辅助
- [[encrypted-backup]]：备份优先
