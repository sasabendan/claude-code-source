---
name: skill-creator
description: 创建新 Skill、优化现有 Skill、测量触发准确率。当用户说"创建 skill"、"优化触发"、"测试 skill"、"建立触发机制"时触发。也用于优化已有 Skill 的 description 字段以提升触发准确率。
---

# Skill: skill-creator

> 来源：anthropics/skills（https://github.com/anthropics/skills/tree/main/skills/skill-creator）
> 适用：本项目有声漫画 Skills 体系维护与优化

---

## 核心循环

```
Draft → Test → Human Review → Improve → Repeat
```

---

## 什么时候用

- 用户想创建一个新 Skill
- 优化已有 Skill 的触发准确率
- 运行 eval 测试 Skill 表现
- 优化 Skill 的 description 字段
- 建立触发测试框架

---

## 创建新 Skill：四步法

### 第一步：Capture Intent（理解意图）

从对话历史或用户描述提取：

1. **这个 Skill 让 Claude 做什么？**
2. **什么时候触发？**（用户会怎么说？列出具体 phrase）
3. **期望的输出格式？**
4. **要不要建立测试用例？**

> 如果 Skill 有客观可验证的输出（文件转换、数据提取、代码生成、固定工作流），建立测试用例很有价值。

### 第二步：写 SKILL.md

目录结构：
```
skill-name/
├── SKILL.md           # 必需：name + description + 正文
├── scripts/           # 可选：可执行脚本
└── references/        # 可选：参考文档
```

**Description 字段规范**（触发核心）：

```markdown
---
name: skill-name
description: 简短动作描述。Use when: "触发词A" / "触发词B" / "具体场景"。
Do NOT use when: "不应触发的情况"。
---
```

Description 越精确，触发越准确。参考本项目规范：
- 包含触发关键词（中英文）
- 包含使用场景
- 包含不触发场景

### 第三步：Test Cases（测试用例）

保存到 `evals/evals.json`：

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "用户实际会说的话（具体、真实）",
      "expected_output": "期望结果"
    }
  ]
}
```

**好的测试 prompt 示例**：
```
"ok so 我要把 tasks/audio-comic-skills/ 目录下的任务书备份到 github，
密码是 omlx2046，怎么弄？"
```

**差的测试 prompt 示例**：
```
"备份文件"
```

### 第四步：Human Review → Improve

1. 运行 with-skill vs without-skill 对比
2. 用户看输出，给反馈
3. 根据反馈改 SKILL.md
4. 重新跑测试
5. 直到用户满意

---

## 触发机制原理

Claude 根据 `available_skills` 列表中的 name + description 决定是否调用 Skill。

**关键规律**：Claude 只会对"自己不容易直接处理"的任务查询 Skill。简单一步操作（如"读这个文件"）即使 description 匹配也可能不触发。

**实战经验**：
- description 写"稍微 push 一点"（包含更多同义表达）
- 包含该 Skill 会帮助的**不同表达方式**（正式/口语）
- should-not-trigger 要写"近失误"（关键词重叠但实际需要不同的 Skill）

---

## 描述优化（Description Optimization）

### 流程

1. 生成 20 个测试查询（should-trigger 8-10 + should-not-trigger 8-10）
2. 用户审阅测试集（编辑/增删/调整 should-trigger 标记）
3. 运行优化循环（最多 5 轮迭代）
4. 应用最优 description 到 SKILL.md

### 生成测试集规范

**should-trigger 查询要求**：
- 覆盖不同表达方式（正式/口语）
- 包含不明确说 Skill 名的隐式需求
- 包含不常见用例
- 包含该 Skill 与其他 Skill 竞争但应该胜出的场景

**should-not-trigger 查询要求**：
- 最有价值：近失误（关键词重叠但实际需要不同）
- 相邻领域
- 歧义短语
- 不要写明显无关的查询（"写 fibonacci 函数"作为 PDF Skill 的负例，太简单，没有测试价值）

---

## 本项目应用

### 当前 Skills 体系

| 类别 | 数量 | 关键 Skill |
|------|------|---------|
| 生产技能 | 5 | audio-comic-workflow |
| 元技能 | 5 | claude-error-handler / claude-first-check |
| 工具技能 | 9 | core-asset-protection / encrypted-backup |
| **合计** | **19** | |

### 已知需要优化的 Skill

| Skill | 优化方向 |
|-------|---------|
| [[core-asset-protection]] | 自动化拦截（proactive guardrail）描述已优化 |
| [[encrypted-backup]] | description 已补全（2026-04-26） |
| [[claude-file-safety]] | 可增加 Do NOT use when 字段 |

### 触发测试框架

当前用手动测试脚本（无 Claude Code CLI）：
```
tasks/audio-comic-skills/skills-test/trigger-test.sh
```

运行方式：
```bash
bash skills-test/trigger-test.sh
```

---

## 相关文件

- `evals/evals.json` — 测试用例集
- `references/schemas.md` — JSON 结构规范
- `agents/grader.md` — 评分规则
- `agents/analyzer.md` — 结果分析规则

---

## 版本历史

### v1.1 (2026-05-01)
- 新增"技能修改自动测试"章节
- 定义 Skill Change Pipeline：三步检测（索引同步/功能可用性/反链一致性）
- 关联约束：C19（发现违规→记录并修复，前置到修改时触发）

### v1.0 (2026-04-30)
- 补录版本历史规则（约束元数据库建设 #BR-002）
- 嵌入 version-history 约束：版本号只追加不覆盖
- 关联约束：C23（补技能不补约束，创建 Skill 时必须遵循）

---

## 扩展：技能修改自动测试（v1.1，2026-05-01 新增）

来源：本会话发现 skills/supervision-anti-drift 和 claude-values 的 KB 条目落后实际文件 2 个版本。

### 核心问题

每次 Skill 文件修改后，知识库索引（.index.jsonl）和反链（_backlinks.json）不会自动同步。需要人工核对，容易遗漏。

### Skill Change Pipeline（多步自动检测）

```
① Skill 文件修改（检测 mtime 变化）
    ↓
② 执行 skill-change-test.sh（四项必检）
    ↓
③ 输出报告（通过/失败/警告）
    ↓
④ 失败 → 按 C19 记录 fail-case → 修复
    ↓
⑤ 成功 → 更新 .index.jsonl updated 字段
```

### 四项必检测试用例

| 测试 | 脚本命令 | 通过条件 |
|------|---------|---------|
| **A. 索引同步** | `grep skill-name .index.jsonl` | `updated` 字段 ≥ 文件修改时间 |
| **B. 功能可用性** | KB 查询模拟（按 tags/name 搜索） | 命中条目数 ≥ 1 |
| **C. 反链一致性** | `grep skill-name _backlinks.json` | 反链条目存在且文件路径有效 |
| **D. 产出物检测** | Python 解析 SKILL.md 脚本引用 | 引用的脚本存在且可执行 |

### 实现代码

`scripts/skill-change-test.sh`：

```bash
#!/bin/bash
# Skill 修改自动测试脚本 v1.1（含 A/B/C/D 四项检测）
# 用法：bash skill-change-test.sh <skill-name>

set -e

SKILL="$1"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
KB_ROOT="$REPO_ROOT/tasks/audio-comic-skills/knowledge-base"
INDEX="$KB_ROOT/.index.jsonl"
BACKLINKS="$KB_ROOT/_backlinks.json"
SKILL_FILE="$REPO_ROOT/skills/$SKILL/SKILL.md"

# 安全递增函数（避免 set -e 下 ((var++)) 返回 1 的问题）
inc_pass()  { PASS=$((PASS+1)); }
inc_fail()  { FAIL=$((FAIL+1)); }
inc_warn()  { WARN=$((WARN+1)); }

# A/B/C 测试（见 skill-change-test.sh 完整实现，含 Python JSON 解析）
# ...

# D. 产出物检测（Python 解析 SKILL.md 脚本引用）
echo "--- D. 产出物检测 ---"
PY_OUT=$(python3 -c "...")
# 提取 scripts/ 路径 → 检查存在+可执行 → PASS/FAIL
if [ 全部存在且可执行 ]; then
  echo "✅ PASS: N 个产出物全部存在且可执行"
  inc_pass
else
  echo "❌ FAIL: 产出物检测未通过"
  inc_fail
fi
```

详见 `scripts/skill-change-test.sh` 完整实现（含 A/B/C/D 四项）。

### 使用场景

| 场景 | 触发时机 |
|------|---------|
| Skill 文件保存后 | 自动检测（或手动运行） |
| 优化 Skill description 后 | 跑三步测试验证索引同步 |
| 每周审视时 | 全量跑 skill-change-test.sh 扫描所有 Skill |

### 全量扫描模式

```bash
# 扫描所有 Skills
for skill in skills/*/SKILL.md; do
  name=$(basename $(dirname "$skill"))
  bash scripts/skill-change-test.sh "$name"
done
```

### 失败处理（C19 联动）

测试失败时：
1. 自动追加 fail-case 条目到 .index.jsonl
2. 输出具体失败项（哪个测试/哪个文件）
3. 脚本返回 exit 1，阻断后续操作

### 关联约束

| 约束 | 联动方式 |
|------|---------|
| C19 | 测试失败 → 记录 fail-case → 不问用户直接修复 |
| C23 | 不通过修改约束来规避测试失败，而是补技能 |
| C24 | Startup Ritual 关联：Skill 修改后 Worker 启动时自动检测 |
