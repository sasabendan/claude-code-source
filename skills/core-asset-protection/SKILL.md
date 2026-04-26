---
name: core-asset-protection
description: 核心资产保护与备份模型执行。触发条件：涉及核心资产文件（任务书/知识库/Skill/备份加密）的一切操作均需先执行本 Skill。
---

# Skill: core-asset-protection（核心资产保护）

> 版本：1.0 | 创建：2026-04-26 | 来源：FC004 根因补救
> 触发场景：涉及核心资产的任何操作之前必须执行

## 核心资产定义

以下文件类型为**核心资产**，任何操作前必须执行本 Skill：

| 类型 | 具体文件 |
|------|---------|
| 任务书 | `TASK_REQUIREMENTS.md` / `TASK_PROGRESS.md` / `master-plan.md` |
| 知识库 | `knowledge-base/` 下所有文件（含 `.index.jsonl` / `_backlinks.json`） |
| Skills | `skills/*/SKILL.md` |
| 参考文档 | `reference-*.md` / `reference-articles/` |
| 项目元数据 | `.project.json` / `CLAUDE.md` / `WRAP.md` |

## 硬约束（禁止违反）

### HC-AP1：本地明文永远保留
**核心资产文件，本地永远保留明文，不删除。**
- GitHub 备份 = 加密 `.enc` 文件（灾难恢复用）
- 本地 = 明文 `.md` 文件（日常使用）
- 两者是**并行关系**，不是**替代关系**
- 加密推送 GitHub 后，**不得删除本地 .md 文件**

### HC-AP2：禁止自动请求删除
**知识库管理的文件，不得自动请求删除。**
- 例外：User 主动明确要求删除
- 触发条件：任何删除操作前，必须先执行本 Skill

### HC-AP3：密码隔离存储
**备份密码存 `~/.backup-password`（chmod 600），不推 GitHub，不备份。**

## 操作规程

### 操作类型 A：加密推送 GitHub

```
① 确认文件是核心资产
② 加密文件 → 生成 .enc → 推 GitHub
③ 本地 .md 明文保留不动          ← 这一步绝对不能跳过
④ 验证：本地有 .md，GitHub 有 .enc
```

**正确**：
```bash
git add TASK_REQUIREMENTS.md.enc
git commit -m "backup"
git push
# 本地 TASK_REQUIREMENTS.md 保持原样
```

**错误（FC004 教训）**：
```bash
git add TASK_REQUIREMENTS.md.enc
git push
rm TASK_REQUIREMENTS.md          ← 禁止！本地永远保留
```

### 操作类型 B：删除文件

```
① 执行 claude-file-safety 判定
② 确认为绿灯文件 → 先备份再删
③ 确认为红灯文件 → 报告禁止删除，询问 User
```

### 操作类型 C：检查备份状态

```bash
# 本地（应有明文）
ls tasks/audio-comic-skills/TASK_REQUIREMENTS.md tasks/audio-comic-skills/TASK_PROGRESS.md tasks/audio-comic-skills/master-plan.md

# GitHub（应有 .enc，无 .md）
git ls-files '*.enc' | grep -E "TASK|master"

# 不一致时（本地缺失但 GitHub 有 .enc）：解密恢复
git show HEAD:tasks/audio-comic-skills/TASK_REQUIREMENTS.md.enc > /tmp/TASK_REQUIREMENTS.md.enc
openssl enc -aes-256-cbc -d -pbkdf2 -in /tmp/TASK_REQUIREMENTS.md.enc \
  -out tasks/audio-comic-skills/TASK_REQUIREMENTS.md -pass file:~/.backup-password
```

## 密码位置

```
~/.backup-password   ← 密码文件（chmod 600），不推 GitHub
```

读取方式：`cat ~/.backup-password`

## 相关 Skill

- [[claude-file-safety]]：删除前判定
- [[encrypted-backup]]：加密备份执行
- [[task-book-keeper]]：任务书管理
- [[knowledge-base-manager]]：知识库管理

## 已知错误案例

| 编号 | 错误内容 | 后果 |
|------|---------|------|
| FC004 | 加密推送后删除本地 .md | 核心资产丢失，已从 GitHub 解密恢复 |
