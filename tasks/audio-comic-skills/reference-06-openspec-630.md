# [Question] OpenSpec v1.0+ 是否仍支持纯自然语言触发 OPSX？
> 来源：https://github.com/Fission-AI/OpenSpec/issues/630
> 作者：Rosetears520
> 日期：2026-01-31

---

## 问题背景

Issue #611 中讨论了 skills 是否必要，以及是否意在支持更"自然语言"的调用方式。当前 README.md 示例主要聚焦于显式命令。

作者的工作流高度依赖 OpenAI Codex CLI `exec` 模式（非交互式）进行自动化。然而 `codex exec` 目前似乎不支持原生斜杠命令：`/opsx:*` 被当作纯文本而非可触发命令/动作。

---

## 核心问题

在 OpenSpec v1.0+ 中，是否仍可能使用**纯自然语言**触发 OPSX 工作流？

### 期望的使用方式

- 自然语言：`"Create a new change for the dark mode feature"`
- 期望行为：Agent 自动选择并执行等效的 OPSX 动作（如 `/opsx:new ...`），而不是要求用户手动输入 `/opsx:new`

---

## v1.0 主要架构变化

1. 引入了 `/opsx:*` 命令系列（取代了之前的 proposal/apply/archive 工作流）
2. 添加了多个 skills（Agent 配置包含约 10 个 OpenSpec 相关 skills）

---

## 关联参考

- OpenSpec 推荐版本：**0.21.0**（本项目采用），因为 0.21.0 之后的工作流使用 skills 触发
- 详情见：`如何使用.md` → "openspec" 部分
