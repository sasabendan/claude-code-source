---
name: claude-first-check
description: 遇到任何工作要求时，第一动作是查记录再行动。遇到问题先查知识库，不知道该做什么先查记录，行为检查顺序：memory-store.jsonl → 任务书 → 知识库 → 才判断是否是新问题。
Do NOT use when: 用户的请求明显在主线范围内且上下文充足（如"继续上一个任务"）。C17 查询应在不确定时执行，不是每次都执行。
---

# Skill: claude-first-check（先查再动）

## 触发条件

满足以下任一场景时自动触发：
- 不知道该怎么处理某件事
- 遇到新工作要求，怀疑可能是老问题
- 不确定某个机制是否存在
- 需要确认密码/配置/路径在哪
- 任何"应该有什么机制但不确定有没有"的时刻

## 核心原则

> 遇到不合理，先去查记录。
> 不知道自己该做什么，先去查记录。

## 检查顺序（强制）

每次遇到工作要求，按以下顺序检查：

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
  
第六步：检查 git commit 历史
  → git log --all --oneline 查是否曾有相关实现
  → git show <commit> 查旧版本内容
  
第七步：只有以上全部确认"不存在"后，才判断是新问题
```

## 典型场景处理

| 场景 | 第一动作 |
|------|---------|
| 不知道某个机制是否存在 | 查 memory-store.jsonl + 任务书 |
| 需要密码/配置 | 查 memory-store.jsonl（Keychain 位置） |
| 怀疑某个功能做过但找不到 | git log 查 commit 历史 |
| 遇到"为什么没做 X" | 查 TASK_PROGRESS.md fail case + git log |
| 新工作要求 | 先查知识库是否已有相关经验条目 |
| 工具来源不清楚 | 查 knowledge-base/.index.jsonl |

## 已知已记录的信息（无需重复查找）

| 信息 | 位置 |
|------|------|
| 备份密码 | `security find-generic-password -s "claude-backup" -w`（Keychain） |
| 主项目路径 | `/Users/jennyhu/claude-code-source` |
| memory-store | `~/.claude/memory-store.jsonl` |
| C0 备份约束 | 每 5 分钟本地备份 + 状态变更触发 git push（**未实现**） |
| C15 分叉任务 | 分叉完成后必须回到主线 |
| C17（新增） | 知识更新后同步到 WRAP.md 状态表 |
| C18（新增） | 3 分钟无任务执行则继续主线当前进度 |

## 常见搜索命令

```bash
# 查 memory-store
grep "<关键词>" ~/.claude/memory-store.jsonl

# 查任务书约束
grep "C0\|C15\|C17\|C18" tasks/audio-comic-skills/TASK_REQUIREMENTS.md

# 查知识库
cat tasks/audio-comic-skills/knowledge-base/.index.jsonl | grep "<关键词>"

# 查 git 历史
git log --all --oneline --follow -- "<文件路径>"
git show <commit> -- "<文件路径>"

# 查 WRAP.md 状态表
grep -A 20 "## 参考文献状态" tasks/audio-comic-skills/WRAP.md
```

## 心跳机制（C18）

每次会话启动时：
1. 读取 `tasks/audio-comic-skills/HEARTBEAT.md`（行为合同）
2. 读取 `tasks/audio-comic-skills/heartbeat-state.md`（状态）
3. 计算距上次会话的时间差

```
session_gap > 3 分钟 → 自检，继续主线
session_gap ≤ 3 分钟 → HEARTBEAT_OK
```

详见：`skills/claude-first-check/heartbeat-rules.md`

## 自我检查清单

每次执行工作前自问：

```
✅ 我知道这件事是否记录过吗？
✅ 我查过 memory-store.jsonl 了吗？
✅ 我查过任务书的约束了吗？
✅ 如果怀疑做过，我查过 git 历史了吗？
✅ 我在假设这是"新问题"之前，已经确认旧记录里没有了吗？
```

## 与其他 Skill 的关系

- 本 Skill 是启动优先级最高的 Skill，每次对话开始时隐式执行
- 独立于 claude-memory，后者负责存取具体记忆
- 本 Skill 负责"检查顺序决策"，claude-memory 负责"取记忆内容"
