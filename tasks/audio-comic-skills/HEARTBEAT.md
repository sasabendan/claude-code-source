# HEARTBEAT.md | 有声漫画 Skills 体系

## 定时规则（C18）

**每次启动时检查 heartbeat-state.md**

- 距上次会话结束 > 3 分钟 → 自检，继续主线当前进度
- 距上次会话结束 ≤ 3 分钟 → HEARTBEAT_OK

## 当前主线进度

**主线**：有声漫画自动化生产 Skills 体系 S0-S5（已完成）
**技术债务**：C0 自动备份（脚本已建，待配 cron）、Rust 重写、OpenSpec 安装

## 心跳规则

详见：`skills/claude-first-check/heartbeat-rules.md`

## 状态文件

`tasks/audio-comic-skills/heartbeat-state.md`
