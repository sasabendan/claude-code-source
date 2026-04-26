---
name: core-asset-protection
description: 核心资产保护与备份模型执行。前置 Skill，强制执行。触发词："加密推送" / "备份到github" / "push" / "删除文件" / "commit" / "删除" / "本地备份" / "enc" / "backup"。涉及核心资产文件（任务书/知识库/Skill/备份加密/版本控制）的一切操作之前必须先调用本 Skill。
---

# Skill: core-asset-protection（核心资产保护）

> 版本：1.0 | 创建：2026-04-26 | 来源：FC004 根因补救

## 定位

**前置 Skill（Utility Skill）**——所有涉及核心资产的写入/删除/推送操作之前，**强制调用**，不得跳过。

## 触发词

**必须触发**（任一出现即调用）：
- "加密推送"、"push"、"commit"、"删除"
- "备份到 github"、"本地备份"、"enc"
- "删除文件"、"本地明文"、"恢复文件"
- 任何涉及核心资产（任务书/知识库/Skill）的 git 操作

**Do NOT use when**：纯查询操作（query/search/list/查看/读取）

## 核心资产范围

| 类型 | 文件 |
|------|------|
| 任务书 | `TASK_REQUIREMENTS.md` / `TASK_PROGRESS.md` / `master-plan.md` |
| 知识库 | `knowledge-base/` 下所有文件 |
| Skills | `skills/*/SKILL.md` |
| 参考文档 | `reference-*.md` / `reference-articles/` |
| 项目元数据 | `.project.json` / `CLAUDE.md` |

## 硬约束体系（HC-AP）

| 约束 | 内容 | 违反后果 |
|------|------|---------|
| **HC-AP1** | 本地明文永远保留，GitHub `.enc` 是并行备份层，非替代 | FC004：核心资产丢失 |
| **HC-AP2** | 知识库管理的文件不得自动请求删除（User 主动要求除外） | 系统性破坏 |
| **HC-AP3** | 密码存 `~/.backup-password`（chmod 600），不推 GitHub，不备份 | 密码泄露 |

## 操作规程

### 加密推送 GitHub

```
① 确认文件属于核心资产范围
② 加密 → 生成 .enc → git add → commit → push
③ 本地 .md 明文原封不动          ← 强制要求
④ 验证：ls 本地 .md 存在 && git ls-files '*.enc' 有对应文件
```

### 删除文件

```
① 执行 [[claude-file-safety]] 判定
② 红灯：报告禁止删除，询问 User
③ 绿灯：先备份再删
```

### 异常恢复（本地缺失但 GitHub 有 .enc）

```bash
# 检测
ls tasks/audio-comic-skills/TASK_REQUIREMENTS.md || echo "本地缺失"

# 恢复
git show HEAD:tasks/audio-comic-skills/TASK_REQUIREMENTS.md.enc \
  > /tmp/TASK_REQUIREMENTS.md.enc
openssl enc -aes-256-cbc -d -pbkdf2 \
  -in /tmp/TASK_REQUIREMENTS.md.enc \
  -out tasks/audio-comic-skills/TASK_REQUIREMENTS.md \
  -pass file:~/.backup-password
```

## 已知错误案例

| 编号 | 错误内容 | 后果 |
|------|---------|------|
| FC004 | 加密推送后删除本地 .md | 核心资产丢失，已从 GitHub 解密恢复 |

## 相关 Skill

- [[claude-file-safety]]：删除前判定
- [[encrypted-backup]]：执行加密备份（依赖本 Skill 前置确认）
- [[task-book-keeper]]：任务书管理，核心资产子类
- [[knowledge-base-manager]]：知识库管理，核心资产子类
- [[claude-error-handler]]：FC004 记录在案（C17→C19 执行链）
