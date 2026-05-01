---
name: supervision-anti-drift
entry_type: skills
created: 2026-04-26T00:40:01.252007+00:00
updated: 2026-04-30T18:50:00Z
tags: [监督验收,漂移检测,checkpoint,NCA,openspec,S4,startup-ritual,two-layer-ledger,hard-gate,governance]
status: stable
source: rosetears.cn/archives/85/
---

# supervision-anti-drift（监督验收）

> 所有环节的监督验收，防止执行偏离原始意图。自动包裹，无需手动触发。
> 源码：`skills/supervision-anti-drift/SKILL.md`（v1.1，2026-04-30）

## 功能定位

所有生成任务的"监工"，确保执行不偏离原始意图。

**核心职责（主编 Agent）**：
- 派发任务给执行 Agent
- 执行验收（运行验证脚本/截图/播放预览）
- 写 EVIDENCE（PASS/FAIL + 证据路径）
- 翻转 passes 状态
- 创建 Git 快照
- 写 progress.txt 交接日志

**职责正交化原则**：写的不验，验的不写。Supervisor 禁止替 Worker 写代码。

## 强制约束

```
openspec==0.21.0  # DO NOT UPGRADE
```

**锁定原因**：v1.0+ 移除了纯自然语言触发 OPSX 的能力，会破坏 Skills 自动触发链路。

---

## 扩展：制度性防跑偏机制（v1.1，2026-04-30 新增）

来源：rosetears.cn/archives/85/ — "Claude Code 监督 Codex"

### 核心问题

| 失败模式 | 表现 |
|---------|------|
| **假完成** | 模型觉得"做完了"，但只是做了个样子 |
| **绕验证** | 偷懒绕过验证，或验证本身不可复现 |
| **跑偏自信** | 跑偏了还自信满满，人手接手时一地鸡毛 |

### Governance：角色禁止边界

| 动作 | 执行 Agent（Worker） | 主编 Agent（Supervisor） |
|------|---------------------|-------------------------|
| 实现功能 + 写 BUNDLE 行 | ✅ | ❌ |
| 读取历史档案（Startup Ritual） | ✅ | ✅ |
| 执行验收（运行脚本/截图/播放） | ❌ | ✅ |
| 写 EVIDENCE（PASS/FAIL） | ❌ | ✅ |
| 翻转 passes 状态 | ❌ | ✅ |
| 创建 Git 快照 | ❌ | ✅ |
| 写 progress.txt 交接日志 | ❌ | ✅ |
| 修改其他环节文件 | ❌ | ❌ |

### Startup Ritual（启动仪式）

每个 Worker 启动前必须执行：
1. 读取 `handoff_log.txt`（上一环节的产出和遇到的问题）
2. 读取 `product_acceptance.json`（当前哪些上游环节已通过）
3. 读取 archive/ 最近 Run 的产出摘要
4. 写入 `logs/startup.txt`（证明"我看过以前发生什么了"）

**解决的核心问题**：subagent 换人就失忆——跨 Agent 上下文不是靠模型记忆力，而是靠**显式档案读取**。

### 两层账本

- **过程账本**（production_pipeline.md）：记录重试、报错、试错细节，人机共见
- **结果账本**（product_acceptance.json）：只有 Supervisor 在完整证据链成立后翻转 passes=false → true

### Immutable Run Folder（证据仓库）

命名格式：`run-<run#>-<step#>-<scene#>-<timestamp>/`

规则：
- 命名含时间戳，永不覆盖历史
- 每个环节完成后追加新文件夹
- Supervisor 验证 PASS 后才写 EVIDENCE
- 证据链断裂 = 任务未完成

## 核心能力

| 能力 | 说明 | 类型 |
|------|------|------|
| Supervisor 角色 | 主编 Agent，职责正交化 | [本地请求] |
| Worker 角色 | 执行 Agent，角色禁止边界 | [本地请求] |
| Startup Ritual | 跨 Agent 记忆传递 | [本地请求] |
| 双层账本 | 过程账本 + 结果账本 | [本地请求] |
| Immutable Run Folder | 不可变证据仓库 | [本地请求] |
| NCA 必要条件阻断 | 不达标即阻断 | [本地请求] |
| 漂移检测 | 对比原始 Spec | [本地请求] |
| 审计日志 | 全量记录 | [本地请求] |
| HARD GATE | 证据链硬门槛 | [本地请求] |

## 监督流程

```
1. 解析原始需求 → 生成规范
2. 执行 Startup Ritual（读取历史档案）
3. 派发给执行 Agent（Worker）
4. Worker 制作 Validation Bundle（不可变产出目录）
5. Supervisor 执行验收（运行 run.sh / 截图 / 播放预览）
6. 漂移 → 中断 → 回滚 → 重新派发
7. 通过 → 产出验收报告
```

## HARD GATE（硬门槛）

任务标记为 DONE 必须同时满足：
- 有 `EVIDENCE (RUN #n)` 行（Supervisor 写）
- 有 `SCOPE: CLI|GUI|MIXED`
- 有 `VALIDATION_BUNDLE: ...` 指向的产物目录存在
- 有 `WORKER_STARTUP_LOG: ...` 证明 Worker 读过历史
- 有 `RESULT: PASS`
- 有 `GIT_COMMIT:` + `COMMIT_MSG:`
- 至少一条证据（截图/音频样本/视频片段）

## NCA 必要条件分析

| 环节 | 必要条件 |
|------|---------|
| 脚本生成 | 字数误差 <10% |
| 分镜设计 | 场景数完整 |
| 生图 | 风格一致性 ≥0.85 |
| 配音 | 情感准确率 ≥0.8 |
| 合成 | 音画同步偏移 <100ms |

## 约束关联

| 约束 | 对应内容 |
|------|---------|
| C24 | Startup Ritual 强制执行 |
| C25 | 角色禁止边界（Worker 越权即 Fail Case） |
| C26 | HARD GATE 证据链硬门槛 |
| C27 | 依赖阻断逻辑（MAXED 阻断依赖环节，不阻断独立环节） |

## 与其他 Skill 的关系

- [[audio-comic-workflow]]：每个环节自动包裹
- [[self-optimizing-yield]]：良品率数据反馈来源
- [[claude-values]]：职责正交化价值观来源

## 版本历史

### v1.0 (2026-04-30)
- 补录版本历史规则（约束元数据库建设 #BR-002）
- 嵌入 version-history 约束：版本号只追加不覆盖
- 关联约束：openspec==0.21.0 锁定（C5 强制约束）

### v1.1 (2026-04-30)
- 内化 rosetears.cn/archives/85/ 制度性防跑偏框架
- 新增 Governance 角色禁止边界表（8项禁止操作）
- 新增 Startup Ritual 机制（跨 Agent 记忆传递）
- 新增两层账本（过程账本 + 结果账本）
- 新增 Immutable Run Folder 规范（含 startup.txt 强制要求）
- 新增 HARD GATE 硬门槛清单（7项）
- 重写监督流程（Startup Ritual → 派发 → 验证 → 通过）
- 关联价值观：[[claude-values]]（职责正交化、证据链优先）
