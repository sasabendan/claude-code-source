---
name: task-book-keeper
description: 任务书管理与核心记忆保留迭代。当用户说"审视任务书"、"更新理解"、"记录进展"、"保留记忆"、"备份任务"、"加密推送"时触发。本 Skill 管理有声漫画自动化生产 Skills 体系的任务书，包含 7 个 Skills（task-book-keeper, knowledge-base-manager, comic-style-consistency, audio-comic-workflow, agi-orchestrator, supervision-anti-drift, self-optimizing-yield）和 14 项约束（C0-C14）。所有任务书内容为核心资产，禁止外传。
---

# Skill: task-book-keeper（任务书管理）

## 功能定位
管理有声漫画自动化生产 Skills 体系的任务书，包含核心记忆保留与迭代。

## 核心能力

| 能力 | 说明 |
|------|------|
| 任务书管理 | 任务需求表、进度表的创建、更新、版本管理 |
| 加密存储 | 使用 AES-256-CBC 加密任务书后再推送 |
| 备份机制 | 本地备份 + GitHub 加密备份 |
| 核心记忆 | 跨会话保留关键理解，支持迭代 |
| 每周审视 | 每周自动审视任务书，主动优化 |

## 输入

```yaml
action:审视|更新|记录|备份|加密推送
task_name: <任务名称>
content: <更新内容，可选>
```

## 输出

```yaml
status: success
action: <执行的操作>
file_updated: <更新的文件>
backup_status: success|failed
```

## 触发场景

| 场景 | 示例 |
|------|------|
| 审视任务书 | "审视任务书" / "查看当前进度" |
| 更新理解 | "更新任务理解" / "记录新认知" |
| 记录进展 | "标记完成" / "更新进度" |
| 备份任务 | "备份当前状态" / "保存进度" |
| 加密推送 | "加密推送" / "安全备份" |

## 核心流程

### 1. 任务书管理

```
任务需求表 (TASK_REQUIREMENTS.md)
    ├── 项目概述
    ├── 七大 Skills 分工
    ├── 约束清单 (C0-C14)
    ├── 参考资料清单
    └── 每周审视机制

任务进度表 (TASK_PROGRESS.md)
    ├── 总体进度
    ├── 阶段一：资料收集
    ├── 阶段二：Skill 产出
    ├── 阶段三：集成验证
    └── 备份记录
```

### 2. 加密备份流程

```bash
# Step 1: 加密
openssl enc -aes-256-cbc -salt -pbkdf2 \
  -in TASK_REQUIREMENTS.md \
  -out TASK_REQUIREMENTS.md.enc \
  -pass stdin

# Step 2: 添加到 Git
git add *.enc

# Step 3: 提交
git commit -m "backup: <描述>"

# Step 4: 推送
git push origin main

# Step 5: 清理本地加密文件
rm -f *.enc
```

### 3. 核心记忆管理

核心记忆存储在 `.claude/refs.jsonl`，格式：

```json
{"id": "main-goal", "created": "2026-04-24T00:00:00Z", "tags": ["task"], "content": "..."}
```

### 4. 每周审视流程

```
1. 审视主线目标理解
2. 审视 Skill 架构合理性
3. 审视执行进度
4. 主动优化不合理之处
5. 更新核心记忆
```

## 参考资料

- 任务书 v0.6（本地）

## 验收标准

- [ ] 任务书结构完整（需求表 + 进度表）
- [ ] 加密备份流程可执行
- [ ] 核心记忆可跨会话保留
- [ ] 每周审视机制已建立

## 代码入口

`skills/task-book-keeper/scripts/backup.sh`
