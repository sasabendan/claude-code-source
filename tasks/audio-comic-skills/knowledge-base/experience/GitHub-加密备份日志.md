---
name: GitHub 加密备份日志
entry_type: experience
created: 2026-04-26T00:00:00.000000+00:00
updated: 2026-04-26T00:00:00.000000+00:00
tags: [github,backup,加密,enc,C11,核心资产]
status: stable
---

# GitHub 加密备份日志

> 版本：1.0 | 更新：2026-04-26
> 约束：[[encrypted-backup]]（C11）| 密码：`~/.backup-password`（chmod 600）
> 加密工具：`bash skills/encrypted-backup/encrypt-backup.sh <password> <git-message> <file1> [file2]...`

---

## 历史备份记录

### 手动备份（有记录可查）

| 日期 | commit | 内容 | 说明 |
|------|--------|------|------|
| 2026-04-24 | `eb25e11` | Skills SKILL.md ×7 + 任务书 + 参考文件加密推送 | 首次批量加密备份 |
| 2026-04-24 | `a4dc828` | Skills ×7 + 参考文件 ×6 加密推送 | 核心资产第一次完整备份 |
| 2026-04-24 | `20c92d8` | TASK_PROGRESS + reference-01 加密推送 | 任务书增量备份 |
| 2026-04-24 | `cedea55` | TASK_PROGRESS + encrypted.tar.gz 加密推送 | 压缩包备份 |
| 2026-04-24 | `4f928ed` | TASK_PROGRESS + TASK_REQUIREMENTS 推送 | 清除明文版本 |

### 自动备份（C0 auto-backup）

自 2026-04-25 19:40 起，每 5 分钟自动备份一次。

```
cron: c0-auto-backup.sh（每5分钟）
GitHub: 95f7b3e → 最新提交
```

---

## 备份范围（核心资产）

以下文件类型为**核心资产**，必须加密备份：

| 类型 | 示例 |
|------|------|
| 任务书 | `TASK_REQUIREMENTS.md` / `TASK_PROGRESS.md` |
| Skills | `skills/*/SKILL.md` |
| 参考文档 | `reference-*.md` |
| 私有文件 | `master-plan.md` / `exported-task.md` |
| 加密产物 | `*.enc`（GitHub 唯一可见格式） |

---

## 本地与 GitHub 状态

| 位置 | 内容 | 说明 |
|------|------|------|
| 本地 | 明文文件 | 日常使用 |
| GitHub | `.enc` 加密文件 | 灾难恢复用 |
| `~/.backup-password` | 密码（chmod 600） | **不推 GitHub，不备份** |
| `memory-store.jsonl` | 密码文件路径 | 查询用，不含明文 |

---

## 加密/解密命令

```bash
# 加密（推 GitHub 前）
bash skills/encrypted-backup/encrypt-backup.sh "$(cat ~/.backup-password)" "备份说明" file1.md

# 解密（恢复时）
openssl enc -aes-256-cbc -d -pbkdf2 -in file.md.enc -out file.md -pass stdin
# 输入密码，或：
openssl enc -aes-256-cbc -d -pbkdf2 -in file.md.enc -out file.md -pass file:~/.backup-password
```

---

## 相关文档

- [[encrypted-backup]] — 加密备份 Skill
- [[task-book-keeper]] — 任务书管理（含加密备份流程）
- [[C-DEV 项目目录约束]] — 测试目录不适用本规则
- [[claude-memory]] — 密码位置记录在 memory-store.jsonl
- [[kb-rust 归档迁移记录]] — kb-rust 归档不在 GitHub（本地备份 `~/.backup/`）
