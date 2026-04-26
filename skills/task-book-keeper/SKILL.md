---
name: task-book-keeper
description: 任务书管理与核心记忆保留迭代。当用户说"审视任务书"、"更新理解"、"记录进展"、"保留记忆"、"备份任务"、"查看进度"时触发。本 Skill 管理有声漫画自动化生产 Skills 体系的任务书（TASK_REQUIREMENTS.md / TASK_PROGRESS.md）。所有任务书内容为核心资产（HC-AP1：本地明文永远保留）。加密推送请调用 encrypted-backup Skill。
Do NOT use when: 用户说"加密推送"、"加密备份"、"安全备份"——应由 encrypted-backup Skill 触发，本 Skill 不越权。
---

# Skill: task-book-keeper（任务书管理）

> 版本：1.1 | 更新：2026-04-26

## 功能定位
管理任务书（需求表/进度表）的创建、更新、版本管理。

## 核心约束

**任务书 = 核心资产，HC-AP1 约束适用：本地明文永远保留。**

加密推送调用 [[encrypted-backup]] Skill，不得自行删除本地 .md 文件。

## 核心能力

| 能力 | 说明 |
|------|------|
| 任务书管理 | 任务需求表、进度表的创建、更新、版本管理 |
| 核心记忆 | 跨会话保留关键理解，支持迭代 |
| 每周审视 | 每周自动审视任务书，主动优化 |

## 输入

```yaml
action: 审视|更新|记录|查看
task_name: <任务名称>
content: <更新内容，可选>
```

## 触发场景

| 场景 | 示例 |
|------|------|
| 审视任务书 | "审视任务书" / "查看当前进度" |
| 更新理解 | "更新任务理解" / "记录新认知" |
| 记录进展 | "标记完成" / "更新进度" |
| 备份任务 | "备份当前状态"（调用 [[encrypted-backup]]） |

## 核心流程

### 任务书结构

```
TASK_REQUIREMENTS.md（任务需求表）
    ├── 项目概述
    ├── 六类 Skills 分工（生产/元/工具）
    ├── 约束清单（C0-C23 + HC-AP）
    ├── 参考资料清单
    └── 每周审视机制

TASK_PROGRESS.md（任务进度表）
    ├── 总体进度
    ├── 阶段一：资料收集
    ├── 阶段二：Skill 产出
    ├── 阶段三：集成验证
    └── 备份记录
```

### 加密备份（调用 [[encrypted-backup]]）

```
不自行执行加密：
① 调用 [[encrypted-backup]] Skill
② [[encrypted-backup]] 执行加密 → 推 GitHub
③ 本地 .md 明文原封不动（HC-AP1）
```

### 每周审视流程

```
1. 审视主线目标理解
2. 审视 Skill 架构合理性
3. 审视执行进度
4. 主动优化不合理之处（C19）
5. 更新核心记忆
```

## 已知错误案例

| 编号 | 错误内容 |
|------|---------|
| FC004 | 加密推送后删除本地 .md（违反 HC-AP1） |

## 相关 Skill

- [[encrypted-backup]]：加密备份执行（task-book-keeper 代理调用）
- [[core-asset-protection]]：核心资产保护，HC-AP1/2/3 约束
- [[knowledge-base-manager]]：知识库管理，同为核心资产

## 代码入口

`skills/task-book-keeper/scripts/backup.sh`
---

## 版本历史

### v1.1 (2026-04-26) ← 当前

**变更**：
- description 更新：移除"加密推送"触发词（由 encrypted-backup 代理）
- 新增 Do NOT use when 子句
- 新增 HC-AP1 约束引用
- 新增[[encrypted-backup]] Skill 引用
- 新增 FC004 已知错误案例
