---
name: task-book-keeper
entry_type: experience
created: 2026-04-26T00:40:15.000000+00:00
updated: 2026-04-26T00:40:15.000000+00:00
tags: [task-book-keeper,任务书管理,加密备份,核心记忆]
status: stable
---

# task-book-keeper（任务书管理）

> 管理有声漫画自动化生产 Skills 体系的任务书。
> 源码：`skills/task-book-keeper/SKILL.md`

## 核心能力

| 能力 | 说明 |
|------|------|
| 任务书管理 | 需求表 + 进度表 + 版本管理 |
| 加密存储 | AES-256-CBC 加密后推送 GitHub |
| 备份机制 | 本地备份 + GitHub 加密备份 |
| 核心记忆 | 跨会话保留关键理解 |

## 管理范围

7 个 Skills：task-book-keeper / knowledge-base-manager / comic-style-consistency / audio-comic-workflow / agi-orchestrator / supervision-anti-drift / self-optimizing-yield

14 项约束：C0-C14

## 每周审视流程

```
审视主线目标理解 → 审视 Skill 架构合理性 → 审视执行进度
→ 主动优化不合理之处 → 更新核心记忆
```

## 与其他 Skill 的关系

- [[encrypted-backup]]：加密备份实现
- [[knowledge-base-manager]]：任务书内容在知识库中可查询
