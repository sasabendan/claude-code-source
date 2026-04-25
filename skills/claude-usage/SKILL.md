---
name: claude-usage
description: Claude Code 使用量追踪与成本计算。当用户说"查看用量"、"查询消耗"、"成本统计"时触发。使用 phuryn/claude-usage 读取本地日志，提供今日/本周/全时段统计。
---

# Skill: claude-usage

## 功能定位
追踪 Claude Code 使用量，计算成本。

## 核心能力

| 能力 | 说明 |
|------|------|
| 今日统计 | `python3 cli.py today` |
| 本周统计 | `python3 cli.py week` |
| 全时段统计 | `python3 cli.py stats` |
| 扫描日志 | `python3 cli.py scan` |

## 使用方法

```bash
# 查看今日用量
python3 skills/claude-usage/cli.py today

# 查看本周用量
python3 skills/claude-usage/cli.py week

# 查看全时段统计
python3 skills/claude-usage/cli.py stats

# 扫描新日志
python3 skills/claude-usage/cli.py scan
```

## 触发场景

| 场景 | 示例 |
|------|------|
| 查看用量 | "查看 Claude 使用量" |
| 成本统计 | "这个月花了多少" |
| 模型分析 | "哪个模型用得最多" |
