---
name: supervision-anti-drift
description: 所有环节的监督验收，防止执行偏离原始意图。当任何环节执行时自动包裹。核心能力包括 checkpoint 验收、漂移检测、审计日志、NCA 必要条件阻断。强制约束：openspec==0.21.0 禁止升级。
Do NOT use when: 用户的请求是纯查询或读取操作，不涉及执行。
---

# Skill: supervision-anti-drift（监督验收）

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
| **跑偏自信** | 跑偏了还自信满满，人接手时一地鸡毛 |

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

```
archive/
└── run-<run#>-<step#>-<scene#>-<timestamp>/
    ├── task.md          # 本环节操作手册 + 验收标准
    ├── run.sh          # 验证脚本（CLI）或启动脚本（GUI 预览）
    ├── logs/
    │   └── startup.txt  # Startup 仪式快照（强制）
    ├── inputs/         # 上游输入
    ├── outputs/        # 本环节产出
    └── evidence/       # Supervisor 截图/音频片段/视频片段
```

---

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

## 输入

```yaml
task_spec: <OpenSpec 格式原始需求>
executor: <被监督的 Agent>
drift_threshold: <0.0-1.0，默认 0.15>
checkpoint_interval: <步数，默认 3>
```

## 输出

```yaml
verdict: pass|fail|drift_detected
evidence: <evidence/ 路径 + hash>
rollback_point: <可恢复的 checkpoint ID>
cost_actual: <实际花费>
```

## 触发场景
自动包裹，无需手动触发。

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

## 验收标准

- [ ] Supervisor 角色明确（不替 Worker 写代码）
- [ ] Worker 角色边界明确（禁止声明 PASS/FAIL）
- [ ] Startup Ritual 已执行（logs/startup.txt 存在）
- [ ] 两层账本对齐（过程账本 + 结果账本 passes 状态）
- [ ] Immutable Run Folder 已创建
- [ ] HARD GATE 所有字段完整
- [ ] 可机读日志
- [ ] 至少 1 个 checkpoint
- [ ] 成本记录
- [ ] 可回滚

## 参考资料

- rosetears.cn/archives/85/（制度性防跑偏框架，来源）
- rosetears.cn/archives/55/（NCA 必要条件分析）
- github.com/Fission-AI/OpenSpec/issues/630（版本锁定）

---

## 扩展：Source Grounding Verification（2026-04-30）

### 新增验收维度

在原有 NCA 必要条件基础上，增加 Source Grounding 验证层。

### 验收流程

```
节点完成后：
1. 检查 extractions.jsonl 存在
2. 验证 char_interval 覆盖率 ≥ 95%
3. 随机抽查 5 个 extraction，核对原文
4. 输出 grounding verification report
```

### 验收标准

| 指标 | 阈值 |
|------|------|
| grounding_rate | ≥ 95% |
| ungrounded_ratio | ≤ 5% |
| char_interval_accuracy | ≥ 98%（抽样验证） |

### 失败处理

grounding_rate < 95% → QA FAIL → 创建 fix 任务
char_interval_accuracy < 98% → QA FAIL → 重新提取

### 相关 Script

```bash
# grounding-verify.sh
bash skills/knowledge-base-manager/scripts/grounding-verify.sh <extractions.jsonl> <original_text>
```

---

## 扩展：Rigor Gaps 检测层（2026-04-28）

参考 EveryInc/compound-engineering-plugin 的 Prose-based probing for logical consistency，作为 NCA 门禁的前置校验层。

### 核心理念

> "Prose-based probing for logical consistency" — 用散文式探测检测方案逻辑自洽性。

### 4维检测框架

| 维度 | 检查内容 | 触发时机 |
|------|---------|---------|
| 前提验证 | 假设是否成立？ | P1 剧本生成前 |
| 依赖验证 | 外部依赖是否可靠？ | P3 生图前（P2 完成后）|
| 边界验证 | 极端情况是否考虑？ | P2 分镜设计前 |
| 逻辑链验证 | 因果关系是否自洽？ | P4 配音参数传递前 |

### 各节点检测脚本

```yaml
rigor_check_P1:
  triggers: ["P1 剧本生成启动前"]
  checks:
    - premise: "原文叙事逻辑是否自洽？"
    - dependency: "目标字数/风格是否可达成？"
    - boundary: "是否存在极端长度章节（>100K字符）？"
    - logic_chain: "角色动机的因果链是否完整？"

rigor_check_P2:
  triggers: ["P2 分镜设计启动前"]
  checks:
    - premise: "剧本场景划分是否合理？"
    - dependency: "分镜工具/API 是否可用？"
    - boundary: "场景数量是否超出合理范围？"
    - logic_chain: "镜头之间的逻辑衔接是否连贯？"

rigor_check_P3:
  triggers: ["P3 生图渲染启动前"]
  checks:
    - premise: "角色视觉描述是否完整？"
    - dependency: "生图 API（MiniMax/Flux）是否可用？"
    - boundary: "分辨率是否在支持范围内？"
    - logic_chain: "LoRA 权重是否与风格一致？"

rigor_check_P4:
  triggers: ["P4 配音合成启动前"]
  checks:
    - premise: "情感参数是否自洽？"
    - dependency: "TTS API 是否可用？"
    - boundary: "音频时长是否合理？"
    - logic_chain: "情感传递链路是否完整？"
```

### 失败处理

任一维度失败 → 生成 Rigor Gap Report → 阻塞流水线直到修复：

```yaml
gap_report:
  node: "P3"
  failed_dimensions: ["premise", "logic_chain"]
  details:
    - "character visual_features 不完整（缺少 '发型颜色' 字段）"
    - "LoRA 权重 1.2 超出 [0.7, 0.9] 合理范围"
  recommendation: "返回 P1 补充 character 视觉描述"
  blocking: true
```

---

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
