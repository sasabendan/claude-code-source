---
type: experience
name: Claude Skills 三层架构
created: 2026-04-25T02:55:35Z
tags: [skill, framework, claude]
---

## Claude Skills 三层架构

### 定位
Claude Skills 的标准结构，将专家知识封装为可复用的能力包。

### 三层结构

| 层 | 内容 | 何时加载 | Token 消耗 |
|---|------|---------|-----------|
| **Level 1** | `name` + `description` | 启动时始终加载 | ~100/skill |
| **Level 2** | SKILL.md 主体 | Skill 被触发时 | ~5k |
| **Level 3** | scripts + reference 文件 | 按需引用时 | 几乎无 |

### 各层职责
- **SKILL.md（SOP层）**：固化程序性知识，告诉 Claude "如何做"
- **scripts/（工具层）**：封装确定性操作，避免重复生成代码
- **reference/（资源层）**：API 文档、配置、示例数据

### 渐进式披露原则
description 是 Level 1 触发的唯一依据，必须写清楚"何时触发"。

### 与本项目的对应
- S1~S5 的 SKILL.md = SOP 层
- scripts/*.sh = 工具层
- reference-*.md + knowledge-base/ = 资源层

### 原文位置
`reference-01-claude-skills-guide.md`

## 相关链接
- [[audio-comic-workflow]]
- [[knowledge-base-manager]]
