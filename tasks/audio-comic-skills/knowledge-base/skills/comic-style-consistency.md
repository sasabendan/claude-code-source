---
name: comic-style-consistency
entry_type: skills
created: 2026-04-26T00:40:01.238736+00:00
updated: 2026-04-26T00:40:01.238736+00:00
tags: [风格锚定,画风,声音一致性,LoRA,S2]
status: stable
---

# comic-style-consistency（风格一致性）

> 当用户说「生成角色」「保持画风」「统一配音风格」时触发。
> 源码：`skills/comic-style-consistency/SKILL.md`

## 核心能力

| 能力 | 说明 |
|------|------|
| 画风锚定 | LoRA 或 reference image 池 |
| 角色一致性 | 固定角色特征参数 |
| 声音一致 | 固定音色 ID + 情感模板 |
| 风格校验 | 一致性分数 ≥ 0.85 |

## 触发场景

- 生成角色形象
- 保持/统一画风
- 统一配音风格

## 良品率关联

- S5 [[self-optimizing-yield]] 根据良品率数据调优风格参数
- 风格锚定参数存入 [[_compiled/concepts/style-parameters.md]]（待建）

## 代码入口

`skills/comic-style-consistency/scripts/style-manager.sh`
