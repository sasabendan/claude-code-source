---
name: minimax-usage
entry_type: experience
created: 2026-04-26T00:40:15.000000+00:00
updated: 2026-04-26T00:40:15.000000+00:00
tags: [minimax,Token-Plan,5h-24h周期,TTS-HD]
status: stable
---

# minimax-usage（MiniMax 用量监控）

> 当用户说「查看 MiniMax 用量」「查询 Token 使用量」时触发。
> 源码：`skills/minimax-usage/SKILL.md`

## 周期类型

| 周期 | 模型 |
|------|------|
| **5小时** | 文本生成, Text to Speech HD, coding-plan-vlm, coding-plan-search |
| **24小时** | music-2.6, music-cover, lyrics_generation, image-01 |

## 使用方法

```bash
python3 skills/minimax-usage/scripts/minimax_usage.py         # 本周期用量
python3 skills/minimax-usage/scripts/minimax_usage.py stats  # 历史统计
```

## 状态指示

| 状态 | 含义 |
|------|------|
| 🔴 | 周期额度已用完或接近用完 (>70%) |
| ⚠️ | 用量较高 (50-70%) |
| ✅ | 用量正常 (<50%) |
