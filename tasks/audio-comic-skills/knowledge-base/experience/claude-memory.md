---
name: claude-memory
entry_type: experience
created: 2026-04-26T00:40:15.085177+00:00
updated: 2026-04-26T00:40:15.085177+00:00
tags: [memory,记忆仓库,Keychain,授权管理]
status: stable
---

# claude-memory（记忆仓库）

> Claude 核心记忆仓库。涉及密码/API Key/配置路径时触发。
> 源码：`skills/claude-memory/SKILL.md`

## 存储位置

所有记忆存于：`~/.claude/memory-store.jsonl`（JSONL 格式）

## 安全约束

- **不存明文密码**：存 macOS Keychain，记忆仓库只记位置
- **不输出敏感内容**：敏感值仅 Claude 自身处理，不直接展示
- **不存 API Key 明文**：只记录获取来源路径

## 授权管理

每次取得明确授权后，追加到 `~/.claude/authorized-scope.jsonl`：
```json
{"date": "2026-04-24", "scope": "加密备份 TASK_REQUIREMENTS.md", "granted_by": "user", "expires": "task_complete"}
```

## 每日打卡

工作未完成期间，每天向用户汇报进展并请求当日授权确认。

## 与其他 Skill 的关系

- [[claude-first-check]]：第一步查询 memory-store.jsonl
- [[encrypted-backup]]：备份密码存 Keychain
