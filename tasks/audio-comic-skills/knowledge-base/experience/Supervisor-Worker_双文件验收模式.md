---
type: experience
name: Supervisor-Worker 双文件验收模式
created: 2026-04-25T02:55:35Z
tags: [supervisor, verification, anti-drift]
---

## Supervisor-Worker 双文件验收模式

### 定位
防止 AI 跑偏和作弊的双重账本机制。

### 两份文件

| 文件 | 颗粒度 | Worker 权限 | Supervisor 权限 | 形态 |
|------|--------|------------|--------------|------|
| tasks.md | 细（1.1, 1.2...） | 添加 BUNDLE 行 | 勾选 checkbox，写 EVIDENCE | Markdown |
| feature_list.json | 粗（1 Ref = 1 功能） | **禁止写入** | 验证通过后改 passes=true | JSON |

### Ref 标签绑定
tasks.md 中每个 checkbox 必须恰好包含一个 `[#R<n>]`，映射到 feature_list.json 的 `"ref": "R<n>"`。

### 状态流转（单向驱动）
1. 先在 tasks.md 验证：Supervisor 运行 Worker 代码包，写入 `EVIDENCE (RUN #n): RESULT: PASS`
2. 后在 feature_list.json 归档：只有 PASS 后才更新 `passes=true`

### 核心价值
双账本让 Supervisor 能发现 Worker 是否"看起来完成了但实际没完成"。

### 原文位置
`reference-03-rosetears-85.md`

## 相关链接
- [[audio-comic-workflow]]
- [[knowledge-base-manager]]
- [[supervision-anti-drift]]
