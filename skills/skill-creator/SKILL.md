---
name: skill-creator
description: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit or optimize an existing skill, run evals to test a skill, benchmark skill performance, or optimize a skill's description for better triggering accuracy.
---

# Skill: skill-creator

> 来源：anthropics/skills（https://github.com/anthropics/skills/tree/main/skills/skill-creator）

## 核心循环

```
Draft → Test (with-skill vs without-skill) → Human Review → Improve → Repeat
```

## 创建新 Skill

### 第一步：Capture Intent
- 从对话历史提取已有工作流（工具/步骤/格式）
- 4 个核心问题：
  1. 这个 Skill 让 Claude 做什么？
  2. 什么时候触发？（用户说什么时）
  3. 期望的输出格式？
  4. 要不要建立测试用例？

### 第二步：Write SKILL.md
```markdown
skill-name/
├── SKILL.md          # 必需
├── scripts/          # 脚本（可执行）
└── references/       # 参考文档
```

Description 字段是触发核心。参考格式：
```
Use when: "关键词A" / "关键词B" / "具体场景"
Do NOT use when: "不应该触发的情况"
```

### 第三步：Test Cases
测试用例保存 `evals/evals.json`：
```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "用户实际会说的话",
      "expected_output": "期望结果描述"
    }
  ]
}
```

### 第四步：运行评估
每个测试用例，同一 prompt 跑两个版本：
- **With-skill**: 加载 SKILL.md 后执行
- **Baseline**: 不加载 SKILL.md 直接执行

### 第五步：Review → Improve → Repeat
- 用户看输出，给反馈
- 根据反馈改 SKILL.md
- 重新跑测试

## 描述优化

Description 是主要触发机制。优化方法：
1. 生成 20 个测试查询（should-trigger + should-not-trigger）
2. 让用户审阅测试集
3. 运行优化循环：`python -m scripts.run_loop --eval-set ... --skill-path ... --max-iterations 5`
4. 应用最优 description

## 本项目适用

| 场景 | 使用 skill-creator |
|------|-------------------|
| 新建 Skill | ✅ 完整走创建流程 |
| 优化现有 Skill 触发 | ✅ 描述优化流程 |
| 日常对话触发 | ❌ 当前用前台 skills/ 目录 |
| MCP 工具 | ❌ 当前无 MCP 环境 |
