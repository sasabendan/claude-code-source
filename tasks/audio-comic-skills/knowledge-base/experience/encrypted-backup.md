---
name: encrypted-backup
entry_type: experience
created: 2026-04-26T00:40:15.000000+00:00
updated: 2026-04-26T00:40:15.000000+00:00
tags: [encrypted-backup,AES-256,Keychain,核心资产]
status: stable
---

# encrypted-backup（加密备份）

> 将敏感文件加密后备份到 Git，本地只保留明文。
> 源码：`skills/encrypted-backup/SKILL.md`

## 核心流程

1. **自动从 Keychain 读取密码**（`security find-generic-password -s "claude-backup" -w`）
2. **加密文件**：`openssl enc -aes-256-cbc -salt -pbkdf2`
3. **Git 添加 → 提交 → 推送 → 清理本地加密文件**

## 密码管理

**密码存储于 `~/.backup-password`**（chmod 600，不推 GitHub，不备份）：
```bash
echo "<password>" > ~/.backup-password && chmod 600 ~/.backup-password
```

## 验收标准

- [x] 加密文件成功生成（.enc 后缀）
- [x] GitHub 上只有加密文件
- [x] 本地只有明文文件
- [x] 推送成功
- [x] 密码不存储在任何明文文件中

## 与其他 Skill 的关系

- [[task-book-keeper]]：任务书加密备份
- [[claude-memory]]：密码文件路径记录在 memory-store.jsonl
- [[GitHub 加密备份日志]]：备份历史记录

## 代码入口

`skills/encrypted-backup/encrypt-backup.sh`
