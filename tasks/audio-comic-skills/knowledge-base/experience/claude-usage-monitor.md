---
name: claude-usage-monitor
entry_type: experience
created: 2026-04-26T00:40:31.000000+00:00
updated: 2026-04-26T00:40:31.000000+00:00
tags: [usage-monitor,Claude额度,token消耗,配额优化]
status: stable
---

# claude-usage-monitor（Claude 额度监控）

> 当用户说「查看额度」「计算消耗」「预估任务成本」时触发。
> 源码：`skills/claude-usage-monitor/SKILL.md`

## 任务类型与消耗估算

| 任务类型 | Haiku 4.5 | Sonnet 4.6 | Opus 4.7 |
|----------|-----------|-------------|-----------|
| 简单查询 | 1K tokens | 3K tokens | 5K tokens |
| 文档生成 | 5K tokens | 15K tokens | 25K tokens |
| 代码生成 | 3K tokens | 10K tokens | 20K tokens |
| 复杂推理 | 10K tokens | 30K tokens | 50K tokens |

## 优化策略

| 场景 | 推荐模型 |
|------|---------|
| 简单对话 | Haiku 4.5 |
| 文档编写 | Sonnet 4.6 |
| 复杂推理 | Opus 4.7 |
| 批量任务 | Haiku + Sonnet |

## 代码入口

`skills/claude-usage-monitor/scripts/usage-calculator.sh`
