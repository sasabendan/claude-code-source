---
name: minimax-usage
description: MiniMax Token Plan 用量监控。当用户说"查看 MiniMax 用量"、"查询 MiniMax 消耗"、"检查 Token 使用量"时触发。显示本周期用量，支持 5小时/24小时周期区分。
---

# Skill: minimax-usage（MiniMax 用量监控）

## 功能定位
监控 MiniMax Token Plan 使用量，显示**本周期用量**。

## 核心能力

| 能力 | 说明 |
|------|------|
| 本周期用量 | `current_interval_usage_count` |
| 总额度 | `current_interval_total_count` |
| 重置倒计时 | `remains_time` |
| 周期分类 | 5小时 / 24小时 |

## 周期类型

| 周期 | 模型 |
|------|------|
| **5小时** | 文本生成, Text to Speech HD, coding-plan-vlm, coding-plan-search |
| **24小时** | music-2.6, music-cover, lyrics_generation, image-01 |

## API 信息

| 项目 | 值 |
|------|-----|
| 端点 | `https://api.minimaxi.com/v1/api/openplatform/coding_plan/remains` |
| 认证 | Bearer Token（自动从 OpenClaw 配置读取） |

## 使用方法

```bash
# 查看本周期用量
python3 skills/minimax-usage/scripts/minimax_usage.py

# 查看历史统计
python3 skills/minimax-usage/scripts/minimax_usage.py stats
```

## 输出示例

```
========================================================================
  MiniMax Token Plan - 今日用量 (2026/04/24)
========================================================================

  ┌─ 📅 5小时周期
  │
  │ 🔴 文本生成
  │    1124/1500 | 74.9% 已使用 | 重置时间: 1小时17分钟后
  │
  │ 🔴 Text to Speech HD
  │    8992/9000 | 99.9% 已使用 | 重置时间: 20小时17分钟后
  │
  │ 🔴 coding-plan-vlm
  │    150/150 | 100.0% 已使用 | 重置时间: 1小时17分钟后
  │
  │ 🔴 coding-plan-search
  │    150/150 | 100.0% 已使用 | 重置时间: 1小时17分钟后
  └─────────────────────────────────────────────

  ┌─ 📆 24小时周期
  │
  │ 🔴 music-2.6
  │    100/100 | 100.0% 已使用 | 重置时间: 20小时17分钟后
  │
  │ 🔴 image-01
  │    100/100 | 100.0% 已使用 | 重置时间: 20小时17分钟后
  └─────────────────────────────────────────────

========================================================================
```

## 状态指示

| 状态 | 含义 |
|------|------|
| 🔴 | 周期额度已用完或接近用完 (>70%) |
| ⚠️ | 用量较高 (50-70%) |
| ✅ | 用量正常 (<50%) |

## 数据存储

| 位置 | 说明 |
|------|------|
| `~/.minimax/usage.db` | SQLite 数据库 |

## 触发场景

| 场景 | 示例 |
|------|------|
| 查看用量 | "查看 MiniMax 用量" |
| 检查消耗 | "查询 Token 使用量" |
| 统计历史 | "查看历史统计" |

## 参考项目

- [phuryn/claude-usage](https://github.com/phuryn/claude-usage)
- [AungMyoKyaw/minimax-usage-checker](https://github.com/AungMyoKyaw/minimax-usage-checker)

## 代码入口

`skills/minimax-usage/scripts/minimax_usage.py`
