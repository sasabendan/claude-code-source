---
name: supervision-anti-drift
description: 所有环节的监督验收，防止执行偏离原始意图。当任何环节执行时自动包裹。核心能力包括 checkpoint 验收、漂移检测、审计日志、NCA 必要条件阻断。强制约束：openspec==0.21.0 禁止升级。
Do NOT use when: 用户的请求是纯查询或读取操作，不涉及执行。
---

# Skill: supervision-anti-drift（监督验收）

## 功能定位
所有生成任务的"监工"，确保执行不偏离原始意图。

## 强制约束

```
openspec==0.21.0  # DO NOT UPGRADE
```

**锁定原因**：v1.0+ 移除了纯自然语言触发 OPSX 的能力，会破坏 Skills 自动触发链路。

## 核心能力

| 能力 | 说明 | 类型 |
|------|------|------|
| OpenSpec 规范 | 规范先行 | [本地请求] |
| 双角色架构 | 监督方+执行方 | [本地请求] |
| checkpoint 验收 | 每个环节验收 | [本地请求] |
| 漂移检测 | 对比原始 Spec | [本地请求] |
| 审计日志 | 全量记录 | [本地请求] |

## 输入

```yaml
task_spec: <OpenSpec 格式原始需求>
executor: <被监督的 LLM>
drift_threshold: <0.0-1.0，默认 0.15>
checkpoint_interval: <步数，默认 3>
```

## 输出

```yaml
verdict: pass|fail|drift_detected
evidence: <hash + 日志路径>
rollback_point: <可恢复的 checkpoint ID>
cost_actual: <实际花费>
```

## 触发场景
自动包裹，无需手动触发。

## 监督流程

```
1. 解析原始需求 → 生成 OpenSpec 规范
2. 拆分为可验收子任务 + NCA 必要条件
3. 派发给执行方
4. 每 checkpoint 三项检查：
   a. 输出 vs Spec 对齐度
   b. 成本 vs 预算
   c. 中间产物可复现性
5. 漂移 → 中断 → 回滚 → 重新派发
6. 通过 → 产出验收报告
```

## NCA 必要条件分析

| 环节 | 必要条件 |
|------|---------|
| 脚本生成 | 字数误差 <10% |
| 分镜设计 | 场景数完整 |
| 生图 | 风格一致性 ≥0.85 |
| 配音 | 情感准确率 ≥0.8 |

## 验收标准

- [ ] OpenSpec 版本 == 0.21.0
- [ ] 可机读 Spec 文件
- [ ] 至少 1 个 checkpoint
- [ ] 成本记录
- [ ] 可回滚

## 参考资料

- rosetears.cn/archives/85/（监督框架）
- rosetears.cn/archives/55/（NCA 必要条件分析）
- github.com/Fission-AI/OpenSpec/issues/630（版本锁定）

## 代码入口

`skills/supervision-anti-drift/scripts/supervisor.sh`

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

