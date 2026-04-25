---
name: claude-usage-monitor
description: Claude 额度监控与消耗计算。当用户说"查看额度"、"计算消耗"、"预估任务成本"时触发。根据任务类型和 token 消耗预估成本，帮助优化配额使用。
---

# Skill: claude-usage-monitor（Claude 额度监控）

## 功能定位
监控 Claude API 使用量，计算任务消耗，优化配额使用。

## 核心能力

| 能力 | 说明 |
|------|------|
| 额度查询 | 查看 Claude 5h 剩余额度 |
| 消耗计算 | 根据任务计算预估消耗 |
| 配额优化 | 建议何时使用 Opus/Haiku |
| 成本追踪 | 记录各任务实际消耗 |

## 输入

```yaml
action: check|estimate|optimize|track
task_type: <任务类型>
task_size: small|medium|large
model: opus-4.6|sonnet-4.6|haiku-4.5
```

## 输出

```yaml
remaining_quota: <剩余额度>
estimated_tokens: <预估 token>
estimated_cost: <预估成本>
recommendation: <优化建议>
```

## 任务类型与消耗估算

| 任务类型 | Haiku 4.5 | Sonnet 4.6 | Opus 4.7 |
|----------|-----------|-------------|-----------|
| 简单查询 | 1K tokens | 3K tokens | 5K tokens |
| 文档生成 | 5K tokens | 15K tokens | 25K tokens |
| 代码生成 | 3K tokens | 10K tokens | 20K tokens |
| 复杂推理 | 10K tokens | 30K tokens | 50K tokens |

## 优化策略

| 场景 | 推荐模型 | 原因 |
|------|---------|------|
| 简单对话 | Haiku 4.5 | 成本最低 |
| 文档编写 | Sonnet 4.6 | 性价比最高 |
| 复杂推理 | Opus 4.7 | 能力最强 |
| 批量任务 | Haiku + Sonnet | 混合策略 |

## 触发场景

| 场景 | 示例 |
|------|------|
| 查看额度 | "查看 Claude 额度" |
| 计算消耗 | "这个任务要花多少" |
| 预估成本 | "预估 10 个任务的消耗" |
| 优化配额 | "怎么优化配额使用" |

## 代码入口

`skills/claude-usage-monitor/scripts/usage-calculator.sh`
