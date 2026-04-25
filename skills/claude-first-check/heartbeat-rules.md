# Heartbeat Rules | claude-first-check

## 来源

主任务 = 边界（C17/C18/C19/C20/C21/C22/C23）

## 每次心跳（会话启动）

1. 读取 `tasks/audio-comic-skills/heartbeat-state.md`
2. 读取 `tasks/audio-comic-skills/HEARTBEAT.md`
3. 计算 `session_gap_minutes`
4. 记录 `last_heartbeat_at`

## 判定

```
session_gap_minutes > 3:
  → 自检：现在该干什么？
  → 读取 TASK_PROGRESS.md 当前进度
  → 继续主线，不空想
  
session_gap_minutes ≤ 3:
  → HEARTBEAT_OK
```

## 安全规则

- 大多数心跳应该什么都不做
- 优先追加、整理，不重写
- 不得删除数据
- 不得在主任务外创建新文件
- 范围不明时，不动，记录待跟进

## 状态字段

`heartbeat-state.md` 必须包含：
- `last_heartbeat_at`
- `last_session_end_at`  
- `session_gap_minutes`
- `last_heartbeat_result`
- `current_main_task`
