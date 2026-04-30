---
type: experience
name: OpenSpec v0.21.0 vs v1.0 差异
created: 2026-04-24T22:36:31Z
tags: [openspec, version]
---

## OpenSpec v0.21.0 vs v1.0 差异

### v0.21.0（推荐）
- 工作流：`proposal → apply → archive`
- 触发方式：显式命令
- 适合场景：本项目采用，与 rosetears 框架兼容

### v1.0（未适配）
- 工作流：重构为 `/opsx:*` 命令系列
- 触发方式：skills 触发（自然语言）
- Codex exec 模式无法原生支持斜杠命令

### 安装
```shell
npm install -g @fission-ai/openspec@0.21.0
openspec init
```

### GitHub Issue #630
https://github.com/Fission-AI/OpenSpec/issues/630

### 原文位置
`reference-06-openspec-630.md`

## 相关链接
- [[kb-rust 归档迁移记录]]
- [[knowledge-base-manager]]
- [[audio-comic-workflow]]
