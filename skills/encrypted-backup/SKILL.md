---
name: encrypted-backup
description: 将核心资产加密后备份到 GitHub。触发词："加密备份" / "加密推送" / "encrypt" / "backup" / "enc" / "备份到 github" / "安全备份"。执行前必须先调用 core-asset-protection 确认 HC-AP1（本地明文永远保留）。密码存 ~/.backup-password。
---

# Skill: encrypted-backup（加密备份）

**Use when**: 用户要求将文件加密后备份到 GitHub
**Do NOT use when**: 只需本地备份（C0 本地备份不加密）、仅查看备份状态

## 依赖

| 工具 | 类型 | 说明 |
|------|------|------|
| openssl | [本地请求] | AES-256-CBC 加密 |
| git | [本地请求] | 提交与推送 |

## 密码管理

**密码存 `~/.backup-password`（chmod 600），不推 GitHub，不备份：**
```bash
# 首次设置
echo "omlx2046" > ~/.backup-password && chmod 600 ~/.backup-password

# 读取
cat ~/.backup-password
```

## 核心约束（HC-AP1，本 Skill 执行前必须确认）

**本地明文永远保留，不删除。**

加密推送 GitHub 后，本地 `.md` 文件原封不动。GitHub 的 `.enc` 是灾难恢复用的并行备份层，两者并行，不是替代关系。

```
✅ 正确流程：
  加密 file.md → 生成 file.md.enc → 推 GitHub → 本地 file.md 保持不变

❌ 错误流程（FC004 教训）：
  加密 file.md → 推 GitHub → 删除本地 file.md  ← 禁止
```

## 脚本入口

`skills/encrypted-backup/encrypt-backup.sh`

## 触发词

- "加密备份"、"加密推送"、"备份到 github"、"encrypt"
- "enc"、"backup enc"、"安全备份"
- **任何涉及核心资产文件（任务书/知识库/Skill）推送 GitHub 之前**

## 执行前检查

1. 调用 [[core-asset-protection]] 确认文件是核心资产
2. 确认本地 `.md` 明文保留（执行后不得删除）
3. 确认密码文件存在：`test -f ~/.backup-password && cat ~/.backup-password`

## 相关 Skill

- [[core-asset-protection]]：前置 Skill，HC-AP1 约束确认
- [[task-book-keeper]]：任务书管理，核心资产子类
