---
name: claude-memory
description: Claude 核心记忆仓库。当用户提及"你之前说过"、"我记得"、"密码在哪"、"API Key 在哪"、"帮我记住"、"你忘了吗"等场景时触发。负责存取 Claude 自身需要长期保留的关键信息（配置路径、关键决策摘要等）。绝不输出原始敏感值本身，只告知存放位置或指引查询方式。
Do NOT use when: 用户问的是新问题而非存取已存储的信息。询问密码/API Key 时必须调用本 Skill。
---

# Claude Memory（记忆仓库）

## 何时触发

- 用户说"你之前说过..."、"你还记得吗"、"密码在哪"
- 用户要求"帮我记住..."某个配置或路径
- 涉及 API Key、密码、敏感配置存放位置的任何问题
- 用户质疑"你又忘了"时，主动查询并报告

## 存储位置

所有记忆存于：`~/.claude/memory-store.jsonl`（JSONL 格式）

管理脚本位置：`skills/claude-memory/scripts/memory_store.py`

## 操作

```bash
# 存（非敏感信息）
python3 skills/claude-memory/scripts/memory_store.py add --key <key> --value <value> --tags tag1,tag2

# 取
python3 skills/claude-memory/scripts/memory_store.py get --key <key>

# 列出
python3 skills/claude-memory/scripts/memory_store.py list

# 按标签筛选
python3 skills/claude-memory/scripts/memory_store.py list --tag api-keys

# 搜索
python3 skills/claude-memory/scripts/memory_store.py search minimax

# 删除
python3 skills/claude-memory/scripts/memory_store.py delete --key <key>
```

## 核心行动准则

**主任务 = 边界。边界之外，必须取得明确授权。**

### 规则
1. 主任务范围内 → 主动执行
2. 主任务范围外 → 不主动做
3. 范围外需要行动 → 先请示，说明原因，等明确授权
4. 已明确授权的重复操作 → 下次自动执行

### 自检流程（每次行动前）
```
问：这是主任务范围内吗？
  是 → 执行
  否 → 问：用户是否已明确授权此操作？
          是 → 执行
          否 → 报告意图 + 原因 → 等授权
```

### 示例
```
❌ 主动检查用户 iCloud 配置（未经授权）
❌ 主动判断某事"应该管"（未经授权）
✅ 主任务需要 → 报告原因 → 取得授权 → 行动
```

## 授权管理协议

### 记录授权范围
每次取得明确授权后，将授权内容追加到 `~/.claude/authorized-scope.jsonl`：
```json
{"date": "2026-04-24", "scope": "加密备份 TASK_REQUIREMENTS.md", "granted_by": "user", "expires": "task_complete"}
{"date": "2026-04-24", "scope": "claude-memory skill 日常维护", "granted_by": "user", "expires": "task_complete"}
```

### 每日打卡
**工作未完成期间，每天向用户汇报进展并请求当日授权确认：**
- 当前进展摘要
- 今日计划
- 请求确认后继续

格式示例：
```
【每日打卡】主线：有声漫画 Skills 体系构建
✅ 已完成：13个 Skills 创建
🔄 进行中：...
📋 待办：...
请确认今日授权继续。
```

### 任务完成 → 授权暂停
主线任务完成后：
1. 将 `authorized-scope.jsonl` 转为 `authorized-scope.<date>.archived.jsonl`
2. 当前会话内所有原授权暂停
3. 新任务需重新申请授权

## 安全约束

- **不存明文密码**：用户告知的密码存 macOS Keychain，记忆仓库只记存放位置
- **不输出敏感内容**：敏感值仅 Claude 自身处理，不直接展示给用户
- **不存 API Key 明文**：只记录获取来源路径
- **不动用户系统**：不修改用户安全配置，不主动扫描系统

## 初始化（每次新会话开始时）

如果涉及之前提到的配置，优先从 `~/.claude/memory-store.jsonl` 查询，而不是问用户。
