---
type: experience
name: compound-engineering-plugin 学习心得
created: 2026-04-30T18:40:00Z
tags: [compound-engineering, skill-design, everyinc,复利化]
关联主线节点: 有声漫画 Skills S0-S5 / 技术债务 / 能力构建部分
---

# compound-engineering-plugin 学习心得

## 项目概况

- **名称**：EveryInc/compound-engineering-plugin
- **规模**：15K⭐ | TypeScript | 50+ Agents + 42 Skills
- **定位**：Official Compound Engineering plugin for Claude Code, Codex, Cursor, OpenCode, OpenClaw 等
- **官网**：https://every.to/guides/compound-engineering
- **安装**：`/plugin install compound-engineering`

## 核心哲学

**每个工程单元都比上一个更容易，而非更难。**

传统开发累积技术债。Compound Engineering 逆转这个趋势：
> 80% 在规划和 review，20% 在执行

核心循环：
```
Brainstorm → Plan → Work → Review → Compound → Repeat
                          ↑
                   （每次循环都让下一个更容易）
```

## 与我们体系的对应关系

| compound-engineering | 我们有声漫画体系 | 对应关系 |
|---------------------|-----------------|---------|
| `/ce-compound` 经验文档化 | auto-distiller | 直接对应 |
| `/ce-compound-refresh` 刷新陈旧经验 | kb-manager 定期维护（待加） | 可增强 |
| `/ce-brainstorm` 交互式需求澄清 | chinese-thinking 三段式总结 | 类似但方向不同 |
| `/ce-plan` 结构化计划 | TASK_REQUIREMENTS.md | 规划层 |
| `/ce-work` worktree + 任务追踪 | 分支任务管理（BR-001/BR-002） | 可升级 |
| `/ce-code-review` 多Agent分层评审 | supervision-anti-drift | 可增强 |
| `/ce-ideate` 代码库主动分析 | kb-overview-supervisor | 方向一致 |
| `/ce-sessions` 跨工具会话历史 | session-check.log / claude-memory | 可升级 |
| `/ce-slack-research` 组织上下文搜索 | GetBiji API（外部知识源） | 类似但数据源不同 |
| 50+ Agents 分层体系 | S0-S5 6层分类体系 | 可参考分层方式 |
| ce-adversarial-reviewer | FC错误案例系统 | 思路类似 |

## 重点借鉴点

### 1. git worktree 多线程开发（高优先级）

`/ce-work` 的核心功能：
- 并行开发多个分支（不污染 main）
- 任务状态追踪
- 与 git worktree 集成

→ 我们当前分支任务（BR-001/BR-002）用 git branch 管理
→ 升级为 worktree 可实现真正并行执行

### 2. 经验刷新机制（/ce-compound-refresh）

当前缺失的维护机制：
- 知识库中的经验随时间陈旧
- 无定期审视和更新流程
- kb-manager 已有构建逻辑，缺刷新逻辑

→ 在 kb-manager 中增加 `kb refresh` 命令
→ 参考：判断 keep/update/replace/archive

### 3. 对抗性评审（ce-adversarial-reviewer）

针对我们的 FC 系统：
- 当前 FC 是被动记录错误
- ce-adversarial-reviewer 是主动构造失败场景
- 可在 supervision-anti-drift 中增加主动风险探测

### 4. 跨工具同步能力

```bash
bunx @every-env/compound-plugin install compound-engineering --to openclaw
```

我们用 OpenClaw → 可直接安装 compound-engineering
→ Skills 格式可跨工具同步
→ 当前我们的 24 个 Skills 不需要同步（单工具维护）
→ 但未来扩展时需考虑格式兼容性

## 不适合我们的部分

| 组件 | 原因 |
|------|------|
| `/lfg` 全自主执行 | 违反 C17/C18（用户授权优先），与 HC-AP 冲突 |
| 自动代码生成/修改 | 需要人工确认（我们的 HC-AP 保护机制） |
| 50+ Agents 规模 | 超出个人维护能力，24 个 Skill 已够用 |
| 多工具同步生态 | 当前单工具维护，不需要复杂同步 |

## 行动计划

- [ ] 安装 compound-engineering 插件到 OpenClaw（可选）
- [ ] 学习 `/ce-work` 实现 git worktree 多线程分支管理
- [ ] kb-manager 增加 `kb refresh` 经验刷新命令
- [ ] 记录 `experience/compound-engineering-plugin.md` 到 KB（本体）
- [ ] supervision-anti-drift 引入对抗性评审思路

## 版本历史

### v1.0 (2026-04-30)
- 初版：compound-engineering-plugin 学习心得
- 关联约束：复利化（self-optimizing-yield）/ C17/C18/HC-AP
- 关联 Skill：skill-creator / supervision-anti-drift / kb-manager / claude-memory
