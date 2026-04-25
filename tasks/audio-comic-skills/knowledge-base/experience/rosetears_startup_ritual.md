---
type: experience
name: rosetears Supervisor 启动仪式
created: 2026-04-24T22:36:31Z
tags: [supervisor, codex, startup]
---

## Supervisor 启动仪式（Worker 执行）

### 触发时机
Worker（Codex）在开始干活前必须执行。

### 执行步骤
1. 读取 `openspec/changes/<change-id>/progress.txt`
2. 读取 `openspec/changes/<change-id>/feature_list.json`
3. 运行 `git log --oneline -20`
4. 将 startup 快照写入 `auto_test_openspec/<change-id>/<run-folder>/logs/worker_startup.txt`

### startup.txt 必须包含
- UTC 时间戳
- CODEX_CMD
- GIT_BASE（`git rev-parse --short HEAD`）
- `git log --oneline -20` 摘要
- 简短"我观察到了什么"总结

### 原文位置
`reference-03-rosetears-85.md`

