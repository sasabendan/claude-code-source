---
name: core-asset-protection
description: 核心资产保护——自动化拦截前置 Skill。当 Claude 准备执行任何 git push / commit / 删除 / 备份 / API Key 操作时，自动激活（无论用户是否主动提醒）。强制确认 HC-AP1：本地明文永远保留，GitHub .enc 是并行备份层而非替代。强制确认 HC-API1/2/3：API Key 禁止远程备份、禁止复制传输、禁止删除。触发词："push" / "commit" / "删除" / "备份到github" / "git add" / "加密" / "API Key" / "配置密钥" / "更新 Key"。Do NOT use when: 纯查询操作（search / query / list / read）。
---

# Skill: core-asset-protection（核心资产保护）

> 版本：1.1 | 更新：2026-04-26 | 来源：FC004 根因补救
> 核心定位：**自动化拦截**，不依赖用户主动提醒

## 定位

**前置自动化拦截 Skill（Proactive Guardrail）**——

Claude 执行任何写入/删除/推送操作前，**自动激活**，无需用户提醒。
这不是问答式 Skill，是**门卫机制**。

## 自动化触发（两种方式）

### 方式一：语言触发（用户主动）
- "push"、"commit"、"删除文件"、"加密推送"、"备份到 github"

### 方式二：自动拦截（核心价值）
**任何写入/删除/推送操作之前，自动调用本 Skill，无需用户提醒。**

```
Claude 准备: git push origin main
  ↓
自动激活 core-asset-protection（无语言触发）
  ↓
HC-AP1 检查 → 确认本地 .md 存在 → 才执行 push
```

## 核心资产范围

| 类型 | 文件 |
|------|------|
| 任务书 | `TASK_REQUIREMENTS.md` / `TASK_PROGRESS.md` / `master-plan.md` |
| 知识库 | `knowledge-base/` 下所有文件 |
| Skills | `skills/*/SKILL.md` |
| 参考文档 | `reference-*.md` / `reference-articles/` |
| 项目元数据 | `.project.json` / `CLAUDE.md` |
| **API Key / Token** | `config.local.json` / `~/.backup-password` / Keychain 条目 |

## 硬约束体系（HC-AP + HC-API）

### HC-AP（文件/资产约束）

| 约束 | 内容 | 违反后果 |
|------|------|---------|
| **HC-AP1** | 本地明文永远保留，GitHub `.enc` 是并行备份，非替代 | FC004：资产丢失 |
| **HC-AP2** | 知识库管理的文件不得自动请求删除（User 主动要求除外） | 系统性破坏 |
| **HC-AP3** | 密码存 `~/.backup-password`（chmod 600），不推 GitHub，不备份 | 密码泄露 |

### HC-API（密钥/Key 约束）

| 约束 | 内容 | 违反后果 |
|------|------|---------|
| **HC-API1** | 禁止远程备份：API Key 不推 GitHub、不写入 .enc、不上传云 | 密钥泄露 |
| **HC-API2** | 禁止复制传输：API Key 不复制到其他文件/工具/日志/正文 | 密钥外泄 |
| **HC-API3** | 禁止删除：已存储的 Key 不得自动删除 | 服务中断 |
| **HC-API4** | 修改必须授权：所有 Key 操作须用户明确授权 | 意外覆盖 |

> 详见：[[API-Key-安全规格]]

## 操作规程

### 加密推送 GitHub

```
① 自动拦截（任何 push/commit 之前激活）
② 确认文件属于核心资产范围
③ 加密 → .enc → git add → commit → push
④ 本地 .md 明文原封不动          ← 强制要求
⑤ 验证：ls 本地 .md 存在 && git ls-files '*.enc' 有对应文件
```

### 删除文件

```
① 自动拦截（任何删除操作之前激活）
② 调用 [[claude-file-safety]] 判定
③ 红灯：报告禁止删除，询问 User
④ 绿灯：先备份再删
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
| FC004 | 加密推送后删除本地 .md（无自动拦截） | 资产丢失，已解密恢复 |

## 相关 Skill

- [[claude-file-safety]]：删除前判定
- [[encrypted-backup]]：执行加密备份
- [[task-book-keeper]]：任务书管理，核心资产子类
- [[knowledge-base-manager]]：知识库管理，核心资产子类
- [[claude-error-handler]]：FC004 记录（C17→C19 执行链）
---

## 版本历史

### v1.2 (2026-04-27) ← 当前

**变更**：
- description 新增 API Key 相关触发词（"API Key" / "配置密钥" / "更新 Key"）
- 新增 HC-API 约束体系（HC-API1/2/3/4）
- 核心资产范围新增 API Key / Token 类型
- 新增 [[API-Key-安全规格]] 引用

### v1.1 (2026-04-26)
- description 重写：从问答式改为 Proactive Guardrail 定位
- 新增自动化拦截机制
- 新增 Do NOT use when 子句
- HC-AP1/2/3 约束体系明确化

### v1.0 (2026-04-26)
- 初始版本：FC004 根因补救建立
