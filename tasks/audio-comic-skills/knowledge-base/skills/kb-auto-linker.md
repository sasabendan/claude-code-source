---
name: kb-auto-linker
entry_type: skills
created: 2026-04-26T00:00:00.000000+00:00
updated: 2026-04-26T00:00:00.000000+00:00
tags: [kb-auto-linker,wikilinks,双链,孤立页面,知识图谱]
status: stable
---

# kb-auto-linker（知识库自动关联）

> 源码：`skills/kb-auto-linker/SKILL.md`
> 版本：1.1 | 创建：2026-04-26 | skill-creator 流程产出

## 定位

**工具技能（Utility Skill）**——知识库双链关联自动化，[[knowledge-base-manager]] 的执行组件。

## 核心发现（Review 后更新）

### 脱孤机制
- inbound link（谁指向我）→ 脱孤
- outbound link（我指向谁）→ **不脱孤**

### 两种策略

| 策略 | 实现 | 效果 |
|------|------|------|
| 策略一（已有）：孤立页面加 outbound link | ✅ v1.1 | Skills 页面 inbound ↑，可导航性 ↑ |
| 策略二（待实现）：hub 页面加 inbound link | ❌ 待开发 | 孤立数实际下降 |

## 实际运行结果

```
运行前：孤立页面 35 个
运行后：孤立页面 34 个（+1 inbound），Skills inbound links +33
```

## 与其他 Skill 的关系

- [[knowledge-base-manager]]：主管，kb-auto-linker 是其执行组件
- [[skill-creator]]：触发测试流程
- [[audio-comic-workflow]]：主要 inbound link 接收方
- [[supervision-anti-drift]]：NCA/Pipeline 相关孤立页面指向目标

---

## 版本历史

### v1.1 (2026-04-26)
- v1.1 更新：Review 后明确脱孤机制（inbound vs outbound）
- 策略一定义完成，策略二待实现

### v1.0 (2026-04-26)
- 初始版本：skill-creator 流程 Draft → Test → Review 完成
- 孤立页面 35→34，Skills inbound +33
