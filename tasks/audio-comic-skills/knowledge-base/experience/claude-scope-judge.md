---
name: claude-scope-judge
entry_type: experience
created: 2026-04-26T00:40:15.043294+00:00
updated: 2026-04-26T00:40:15.043294+00:00
tags: [scope-judge,范围判定,红灯绿灯,边界]
status: stable
---

# claude-scope-judge（范围判定）

> 行为和任务书约定范围不符时的判定规则。
> 源码：`skills/claude-scope-judge/SKILL.md`

## 核心原则

**主任务 = 边界。边界之外，必须取得明确授权才能行动。**

## 红灯禁止

- 自建任务书体系外的文档当主任务做
- 用错误范例关键词修改任务书约束
- 超出主线任务范围主动发起新工作
- 空等用户指令（C18：3分钟无动作则自检继续）

## 绿灯通行

- 在主线任务范围内遇到错误 → 修复 + 记录（C19）
- 发现违规 → 记录 + 修复，不问用户
- User 明确授权的文件 → 直接建

## 文件边界判定

禁止新建的文件（除非明确授权）：
- git 历史中不存在的
- Skill SKILL.md 不引用的
- TASK_REQUIREMENTS/PROGRESS/CLAUDE 中没有出现过的

## 与其他 Skill 的关系

- [[claude-first-check]]：先查再动，提供信息来源
- [[claude-values]]：价值观判断，什么重要/该不该做
- [[claude-error-handler]]：错误发生时的处理
