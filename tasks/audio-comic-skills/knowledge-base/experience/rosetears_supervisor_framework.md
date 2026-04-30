---
type: experience
name: rosetears Supervisor-Worker 框架
created: 2026-04-24T22:36:31Z
tags: [supervisor, codex, openspec]
---

## rosetears Supervisor-Worker 框架

### 定位
Claude Code 监督 Codex 的可复现验收与防跑偏实践框架。

### 核心原则
- **Supervisor（Claude Code）**：派发任务、验收确权、更新状态
- **Worker（Codex）**：只写代码 + 制作可复现测试方案
- **禁止 Worker**：勾选 tasks.md、修改 feature_list.json、声明 PASS/FAIL

### 三记忆文件
| 文件 | 定位 | 写入权限 |
|------|------|---------|
| tasks.md | 过程记录 | Supervisor 勾选；Worker 添加 BUNDLE 行 |
| progress.txt | 交接日志 | Supervisor 追加 |
| feature_list.json | 功能验收状态 | 完全禁止 Worker 修改 |

### Ref 标签绑定
tasks.md 中每个 checkbox 必须恰好包含一个 `[#R<n>]`，映射到 feature_list.json 的 `"ref": "R<n>"`。

### Run Folder 不可变性
命名：`run-<run#>__task-<id>__ref-<ref>__<ts>/`；历史永不覆盖，追加新文件夹。

### 目录结构
```
auto_test_openspec/<change-id>/<run-folder>/
git_openspec_history/<change-id>/runs.log
openspec/changes/<change-id>/{tasks.md,feature_list.json,progress.txt}
```

### 确权四步
1. 勾选 tasks.md checkbox
2. 更新 feature_list.json 的 passes=true
3. Git 提交存档
4. 写 progress.txt 交接日志

### 原文位置
`reference-03-rosetears-85.md`
`/Users/jennyhu/Documents/Claude code - openspec - codex(1)/`

## 相关链接
- [[audio-comic-workflow]]
- [[knowledge-base-manager]]
- [[supervision-anti-drift]]
