---
name: claude-first-check
entry_type: experience
created: 2026-04-26T00:40:15.057255+00:00
updated: 2026-04-26T00:40:15.057255+00:00
tags: [first-check,先查再动,检查顺序,C17,7步检查]
status: stable
---

# claude-first-check（先查再动）

> 遇到任何工作要求时，第一动作是查记录再行动。
> 源码：`skills/claude-first-check/SKILL.md`

## 检查顺序（强制）

```
第一步：~/.claude/memory-store.jsonl
  → 查关键配置、路径、密码位置、已知决策

第二步：tasks/audio-comic-skills/TASK_REQUIREMENTS.md
  → 查约束（C0-C18）、Skill 架构、触发条件

第三步：tasks/audio-comic-skills/TASK_PROGRESS.md
  → 查进度、待办、已知失败点（fail case）

第四步：tasks/audio-comic-skills/knowledge-base/.index.jsonl
  → 查经验知识、工具来源、已记录的工具链

第五步：各 Skill SKILL.md
  → 查具体能力范围、触发词、代码入口

第六步：git commit 历史
  → git log --all --oneline 查是否曾有相关实现

第七步：只有以上全部确认「不存在」后，才判断是新问题
```

## 典型场景

| 场景 | 第一动作 |
|------|---------|
| 不知道某个机制是否存在 | 查 memory-store.jsonl + 任务书 |
| 需要密码/配置 | 查 memory-store.jsonl（Keychain 位置） |
| 怀疑某个功能做过但找不到 | git log 查 commit 历史 |
| 遇到「为什么没做 X」 | 查 TASK_PROGRESS.md fail case + git log |

## 心跳机制（C18）- 自动触发闭环

### SessionStart Hook → heartbeat-service.sh

```
~/.claude/settings.json SessionStart Hook
         ↓
  heartbeat-service.sh（每次会话启动自动执行）
         ↓
  计算 session_gap = now - ~/.claude/heartbeat.json mtime（分钟）
         ↓
  gap > 3 分钟 → SELF_CHECK → 继续主线当前节点
  gap ≤ 3 分钟 → HEARTBEAT_OK（无需干预）
         ↓
  更新 heartbeat-state.md（下次自检依据）
```

### 当前状态（2026-04-27 实测）

- SessionStart Hook 已配置 → `~/.claude/settings.json`
- heartbeat-service.sh 已创建 → `skills/claude-first-check/scripts/heartbeat-service.sh`
- 本次 gap = 3047 分钟 → 触发自检，heartbeat-state.md 已更新
- 当前主线：有声漫画 Skills S0-S5 全部完成，技术债务待推进

## 与其他 Skill 的关系

- [[claude-scope-judge]]：范围判定，红灯/绿灯
- [[claude-memory]]：存取具体记忆内容

## 版本历史

### v1.1 (2026-04-27)
- 心跳机制（C18）自动闭环实现：SessionStart Hook → heartbeat-service.sh
- 新增 `scripts/heartbeat-service.sh`：gap > 3分钟 → 自动自检 + 更新 heartbeat-state.md
- Hook 绑定：`~/.claude/settings.json` SessionStart Hook 调用 heartbeat-service.sh
- 实测：gap=3047分钟，触发自检，heartbeat-state.md 已更新

### v1.0 (2026-04-26)
- 初始版本：7步检查顺序 + C18 心跳规则文档化
- claude-first-check SKILL.md 完成
