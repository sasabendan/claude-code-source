---
name: skill-creator
entry_type: skills
created: 2026-04-26T00:00:00.000000+00:00
updated: 2026-04-26T00:00:00.000000+00:00
tags: [skill-creator,触发机制,测试框架,eval,description优化]
status: stable
---

# skill-creator（Skill 创建与优化）

> 源码：`skills/skill-creator/SKILL.md`
> 来源：anthropics/skills（GitHub）

## 定位

**元技能（Meta Skill）**——用于创建新 Skill 和优化现有 Skill 的触发机制。

## 核心价值

Skills 的 description 字段决定触发准确率。skill-creator 提供了：
1. **测试框架**：with-skill vs baseline 对比
2. **量化评估**：pass rate / timing / token 统计
3. **描述优化**：自动化迭代 description 触发词

## 本项目应用场景

| 场景 | 操作 |
|------|------|
| 新建 Skill | 走 skill-creator 完整流程 |
| 优化现有 Skill 触发 | 运行描述优化循环 |
| 验证 Skills 体系 | 当前用手动触发测试脚本 |

## 与其他 Skill 的关系

- 所有 19 个现有 Skill 均可用 skill-creator 优化触发
- [[audio-comic-workflow]]：主触发入口
- [[core-asset-protection]]：已有清晰的触发词和 Do NOT use when
