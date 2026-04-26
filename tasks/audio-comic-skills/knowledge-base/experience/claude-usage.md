---
name: claude-usage
entry_type: experience
created: 2026-04-26T00:40:31.000000+00:00
updated: 2026-04-26T00:40:31.000000+00:00
tags: [usage,用量追踪,成本计算,phuryn]
status: stable
---

# claude-usage（Claude 用量追踪）

> 当用户说「查看用量」「查询消耗」「成本统计」时触发。
> 源码：`skills/claude-usage/SKILL.md`

## 使用方法

```bash
python3 skills/claude-usage/cli.py today     # 今日统计
python3 skills/claude-usage/cli.py week       # 本周统计
python3 skills/claude-usage/cli.py stats     # 全时段统计
python3 skills/claude-usage/cli.py scan      # 扫描新日志
```

## 与其他 Skill 的关系

- [[claude-usage-monitor]]：Claude 额度监控与配额优化
- [[minimax-usage]]：MiniMax Token Plan 用量
