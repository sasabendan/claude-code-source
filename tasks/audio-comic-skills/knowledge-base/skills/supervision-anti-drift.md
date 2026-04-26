---
name: supervision-anti-drift
entry_type: skills
created: 2026-04-26T00:40:01.252007+00:00
updated: 2026-04-26T00:40:01.252007+00:00
tags: [监督验收,漂移检测,checkpoint,NCA,openspec,S4]
status: stable
---

# supervision-anti-drift（监督验收）

> 所有环节的监督验收，防止执行偏离原始意图。自动包裹，无需手动触发。
> 源码：`skills/supervision-anti-drift/SKILL.md`

## 强制约束

**openspec==0.21.0 锁定**：v1.0+ 移除了纯自然语言触发 OPSX 的能力，会破坏 Skills 自动触发链路。

## NCA 必要条件

| 环节 | 必要条件 |
|------|---------|
| 脚本生成 | 字数误差 <10% |
| 分镜设计 | 场景数完整 |
| 生图 | 风格一致性 ≥0.85 |
| 配音 | 情感准确率 ≥0.8 |

## 监督流程

```
解析原始需求 → 生成 OpenSpec 规范
  → 拆分为可验收子任务 + NCA 必要条件
  → 派发给执行方
  → 每 checkpoint 三项检查（输出对齐/成本/可复现性）
  → 漂移 → 中断 → 回滚 → 重新派发
  → 通过 → 产出验收报告
```

## 与其他 Skill 的关系

- [[audio-comic-workflow]]：每个环节自动包裹
- [[self-optimizing-yield]]：良品率数据反馈来源

## 代码入口

`skills/supervision-anti-drift/scripts/supervisor.sh`
