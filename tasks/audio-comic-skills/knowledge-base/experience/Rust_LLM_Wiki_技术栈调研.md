---
type: experience
name: Rust LLM Wiki 技术栈调研
tags: [knowledge-base, research, rust, llm-wiki, qdrant, moltis]
created: 2026-04-28T14:16:00Z
source: Claude Code AI 研究 + 外部咨询
status: reference
---

# Rust LLM Wiki 技术栈调研

更新时间：2026-04-28
来源：Claude Code AI 研究 + 外部咨询

## 核心结论

目前没有完全"开箱即用"的 Rust 版 LLM Wiki 成品。
Karpathy 的 LLM Wiki 是一种**工作流理念**，而非具体软件。
可通过组合 Rust 生态项目搭建完整知识库。

## 推荐技术栈组合

### 1. 向量存储与检索：Qdrant

| 特性 | 说明 |
|------|------|
| 性能 | Rust 原生，比 Python 方案快数倍 |
| 过滤 | 支持日期、分类、用户 ID 等复杂元数据 |
| 部署 | Docker 自托管，完全本地运行 |
| 集成 | HTTP/gRPC API，任何语言可接入 |

### 2. Agent 框架：Moltis（Rust 重写）

- 统一模型接口：OpenAI API / Ollama / 本地 LLaMA
- 故障转移链：主模型超时自动降级备用模型
- 本地优先：完全离线，数据不出本地
- 会话沙箱：Docker/Apple Container 隔离

### 3. Rust Agent SDK：Open Agent

- 原生 async/await + Tokio
- 支持流式响应、工具调用、生命周期钩子
- 零 API 成本，隐私优先

### 4. 笔记/API 接入方案

| 笔记工具 | 接入方式 |
|---------|---------|
| Obsidian | 本地 Markdown + Local REST API 插件 |
| Notion | 官方 API，双向同步 |
| Logseq | 本地文件 + Git 同步 |
| **得物笔记（GetBiji）** | 官方 OpenAPI（本项目目标） |
| 通用 | MCP (Model Context Protocol) |

### MCP 是关键

Anthropic 开源的 MCP 已成为 Agent 世界的"USB-C"标准。
超过 3000 个 server 支持 GitHub、Notion、Slack 等。
Rust 有官方 MCP SDK 实现。

## 推荐架构图

```
前端层（Obsidian/CLI）
    Markdown Wiki + index.md + schema.md
              ↓ 本地文件/REST API
处理层（Rust）
  Moltis Agent框架 ◄──► Open Agent SDK
              ↓ LLM API（Ollama/本地模型）
              ↓ 向量化/检索
存储层（Rust）
  Qdrant 向量数据库 + 本地文件系统（raw/ wiki/）
              ↓
外部笔记 API（MCP/REST）
  GetBiji / Notion / GitHub / 其他笔记
```

## 快速启动建议

1. **先用 Obsidian 搭 LLM Wiki 结构**：purpose.md + schema.md + raw/ + wiki/
2. **接入 Qdrant**：Docker 一键启动，把 wiki 内容向量化
3. **用 Moltis 或 Open Agent SDK 写 Rust Agent**：ingest → summarize → update wiki 闭环
4. **通过 MCP 接入外部笔记**：把 GetBiji/Notion 作为 Agent 的工具/资源

## 与我们项目的关联

| 需求 | 对应方案 |
|------|---------|
| Rust 构建 | Qdrant + Moltis / Open Agent SDK |
| LLM Wiki 理念 | Obsidian + Markdown 目录结构 + schema 驱动 |
| 接入 Agent/大模型 | Moltis 框架 + MCP 协议 |
| 接入得物笔记 API | MCP Server 或 REST API（本项目 S1 目标） |
| 完全本地 | Ollama + Qdrant 自托管 + Moltis 离线模式 |

## 未完成事项（关联本项目）

- [ ] 得物笔记（GetBiji）API 接入（目标：S1 knowledge-base-manager 双数据源之一）
- [ ] kb-rust 增加 AI 问答能力（参考 kb-overview-supervisor）
- [ ] pdf-ingest 实现（参考 bkywksj/knowledge-base 的 PDF 导入）
- [ ] 知识图谱可视化（参考 bkywksj/knowledge-base 的链接可视化）

## 参考资料

- Qdrant: https://qdrant.tech/
- Moltis: Rust Agent 框架（待查 GitHub）
- bkywksj/knowledge-base: https://github.com/bkywksj/knowledge-base（GUI 参考）
- 得物笔记 API: reference-02-biji-api.md
