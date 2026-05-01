---
name: task-book-keeper
entry_type: experience
created: 2026-04-26T00:40:15.000000+00:00
updated: 2026-04-30T18:50:00Z
tags: [task-book-keeper,任务书管理,加密备份,核心记忆]
status: stable
---

# task-book-keeper（任务书管理）

> 管理有声漫画自动化生产 Skills 体系的任务书。
> 源码：`skills/task-book-keeper/SKILL.md`

## 核心能力

| 能力 | 说明 |
|------|------|
| 任务书管理 | 需求表 + 进度表 + 版本管理 |
| 加密存储 | AES-256-CBC 加密后推送 GitHub |
| 备份机制 | 本地备份 + GitHub 加密备份（C0 每5分钟自动） |
| 核心记忆 | 跨会话保留关键理解 |

## 管理范围

**Skills（6个核心 + 11个工具 = 17个）**：
- S0 task-book-keeper / S1 knowledge-base-manager / S2 comic-style-consistency
- S3 audio-comic-workflow / S4 supervision-anti-drift / S5 self-optimizing-yield
- 工具 Skills：chinese-thinking / claude-first-check / claude-error-handler / claude-scope-judge 等

**约束（28项，C0-C27）**：
- 核心约束：C0 定时备份 / C9 参考对照 / C10 核心资产保护 / C11 加密策略 / C12 本地维护 / C13 任务书迭代 / C14 核心记忆保留
- 技术约束：C1 技术栈 / C2 标注规范 / C3 模型选型 / C4 监督机制 / C5 版本锁定 / C6 成本上限 / C7 审计要求 / C8 可复现性
- 流程约束：C15 分叉任务管理 / C16 优先现有条件 / C17 查询顺序 / C18 3分钟无动作自检 / C19 发现违规记录并修复
- 错误处理：C20 错误范例关键词≠修改依据 / C21 修改依据=任务主线 / C22 错误范例仅作查询依据 / C23 补技能不补约束
- 制度性防跑偏：C24 Startup Ritual / C25 角色禁止边界 / C26 证据链硬门槛 / C27 依赖阻断逻辑

## 每周审视流程

```
审视主线目标理解 → 审视 Skill 架构合理性 → 审视执行进度
→ 主动优化不合理之处 → 更新核心记忆
→ 审视 Startup Ritual 执行情况（logs/startup.txt 覆盖率）
→ 审视两层账本对齐情况（production_pipeline.md vs product_acceptance.json）
→ 审视角色越权记录（Fail Case 中是否有 Agent 越权）
→ 审视 HARD GATE 遵守情况（EVIDENCE 字段完整性）
```

## 版本历史

### v0.6 (2026-04-24)
- 初始化任务书

### v0.7 (2026-04-30)
- 内化 rosetears 制度性防跑偏框架
- 新增 Stage 0 预提取流程
- 新增 3 项关键词（证据链优先/职责正交化/Startup Ritual）
- S3 增加 Supervisor-Worker 架构说明
- S4 更新核心能力描述
- 新增约束 C24-C27
- 新增 Supervisor-Worker 架构映射表
- 每周任务增加制度性框架审视项（Startup Ritual/两层账本/角色越权/HARD GATE）

## 与其他 Skill 的关系

- [[encrypted-backup]]：加密备份实现（C11 Keychain）
- [[knowledge-base-manager]]：任务书内容在知识库中可查询
- [[supervision-anti-drift]]：制度性防跑偏执行层（C24-C27 来源）
