---
name: claude-file-safety
description: 判断文件是否可安全删除。触发条件：需要删除任何文件时，先判断主线任务相关性和上下文影响再决定。
Do NOT use when: 纯查询操作（查看/读取/搜索文件）不涉及删除。删除临时文件（*.tmp/*.bak/*.log）时仍建议检查，但非强制。
---

# Skill: claude-file-safety（文件安全删除判定）

## 触发条件

需要删除任何文件时，必须先执行本 Skill，不直接删除。

## 判定流程

### 第一步：主线任务相关性检查

判断文件是否与主线任务相关：

```
在以下位置中任一出现 → 主线相关（红灯/谨慎）
  - TASK_REQUIREMENTS.md 中的任何版本
  - TASK_PROGRESS.md 中的任何版本
  - HEARTBEAT.md
  - CLAUDE.md
  - master-plan.md
  - knowledge-base/.index.jsonl 的任何条目

在以下位置任一出现 → 主线相关（需额外确认）
  - git commit 历史
  - 其他 Skill SKILL.md 中引用

不在上述任何位置 → 可删除（绿灯）
```

### 第二步：上下文依赖检查

如果文件在主线相关范围内，进一步检查：

```
文件是否被其他文件引用？
  → git grep "<文件名>" 检查所有 .md / .sh / .json 文件
  → 检查 knowledge-base/.index.jsonl 是否有指向该文件的条目
  → 检查 Skill SKILL.md 是否有引用

有引用 → 红灯，不删除，除非该引用本身就是错误（C20）

无引用 → 谨慎删除，先备份再删
```

### 第三步：备份优先

即使判定可删除，也先备份：

```bash
cp <文件> tasks/audio-comic-skills/backups/$(basename <文件>).bak.$(date +%Y%m%d%H%M%S)
```

### 第四步：删除后验证

```
删除后执行 git status
确认删除的文件从 git 跟踪中消失
```

## 红灯（禁止删除）

- 任务书体系内的任何文件（无论是否"未授权"）
- 知识库条目指向的文件
- Skill SKILL.md 引用的文件
- HEARTBEAT.md / heartbeat-state.md
- TASK_PROGRESS.md / TASK_REQUIREMENTS.md

## 绿灯（可直接删除）

- 不在任何体系内的文件（git 历史/引用/索引均无）
- 临时文件（*.tmp / *.bak / *.log）

## 已知绿灯文件（可删除示例）

| 文件 | 原因 |
|------|------|
| WRAP.md | 未在 git 历史/任务书/知识库中出现，无任何引用 |
| skills/heartbeat.sh | 越权创建的伪心跳脚本，无任何引用，无实际功能 |

## 示例场景

**场景**：用户要求删除 HEARTBEAT.md
**判定**：红灯 → 禁止删除 → 报告文件在体系内，删除会破坏心跳机制

**场景**：用户要求删除 WRAP.md
**判定**：绿灯 → 可删除 → 先备份，执行删除，验证 git status

---

## 版本历史

### v1.0 (2026-04-30)
- 补录版本历史规则（约束元数据库建设 #BR-002）
- 嵌入 version-history 约束：版本号只追加不覆盖
- 关联约束：hc-ap3（禁止自动删除核心资产）
