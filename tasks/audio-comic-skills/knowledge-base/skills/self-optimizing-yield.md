---
name: self-optimizing-yield
entry_type: skills
created: 2026-04-26T00:40:01.265279+00:00
updated: 2026-04-26T00:40:01.265279+00:00
tags: [良品率,反馈闭环,经验库,贾维斯化,S5]
status: stable
---

# self-optimizing-yield（良品率优化）

> 每次生产批次结束后自动触发，持续优化良品率。
> 源码：`skills/self-optimizing-yield/SKILL.md`

## 良品率指标

```
yield_rate = 一次通过数 / 总生产数
```

分环节统计：脚本通过率 / 分镜通过率 / 生图通过率 / 配音通过率 / 合成通过率

**目标**：每周环比提升 ≥3%，直到 ≥95%

## 优化回路

```
失败案例 → 归因分析 → 生成新 prompt → A/B 测试 → 胜出者入库
```

## 防退化保护

- 连续 3 次不如旧策略 → 自动回滚
- 金标准测试集不通过 → 自动回滚
- 良品率下降 >10% → 自动回滚

## 与其他 Skill 的关系

- [[comic-style-consistency]]：根据良品率调优风格参数
- [[supervision-anti-drift]]：NCA 数据反馈来源
- [[knowledge-base-manager]]：经验库使用 LLM Wiki 架构

## 代码入口

`skills/self-optimizing-yield/scripts/yield-optimizer.sh`
