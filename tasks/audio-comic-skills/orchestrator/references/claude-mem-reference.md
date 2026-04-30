# claude-mem 技术参考

> 来源：https://github.com/thedotmack/claude-mem
> 学习时间：2026-04-30
> 相关性：分层记忆、生命周期钩子、自动蒸馏、MCP Server

## 核心设计

### 三层记忆架构

```
Level 1: Meta-Index（关键词/标签索引）
  - 放入内存，极轻量
  - 快速定位候选
  
Level 2: Summary（语义摘要）
  - 存入 SQLite
  - 蒸馏后的语义信息
  
Level 3: Raw Context（原始代码片段）
  - 仅在 AI 明确要求时加载
  - 降低 Token 消耗
```

**借鉴意义**：解决 Mac Mini 16GB 内存的向量数据库压力

### 生命周期钩子（6个）

| 钩子 | 时机 | 功能 |
|------|------|------|
| Context Hook | SessionStart | 启动 Bun Worker，注入上下文 |
| New Hook | UserPromptSubmit | 创建 session，保存原始 prompt |
| Save Hook | PostToolUse | 捕获工具执行，发送 Worker 处理 |
| Summary Hook | Stop | 生成会话总结 |
| Cleanup Hook | SessionEnd | 标记 session 完成 |
| Smart Install | Pre-hook | 依赖检查（版本变化时运行） |

**关键钩子**：PostToolUse 用于自动蒸馏

### Progressive Disclosure（渐进式披露）

```
搜索流程（3层）：
1. search → 获取紧凑索引（~50-100 tokens/result）
2. timeline → 获取时间上下文
3. get_observations → 获取完整详情（~500-1000 tokens/result）

Token 节省：~10x（过滤后再取详情）
```

### 自动蒸馏触发

```typescript
// PostToolUse 钩子触发
// 当 AI 完成工具调用（如 edit_file）后自动触发
// 自动提取"成功经验"并蒸馏存档

interface Observation {
  tool: string;
  args: Record<string, any>;
  result: any;
  distilled: string;  // AI 生成的语义摘要
}
```

## 数据库设计

```sql
-- 实体类型（可扩展）
type: bugfix | feature | context | ...

-- Source Grounding
char_interval: [start, end]  // 原文位置
source_file: string
```

**借鉴**：Character_Voice_Preset / Timeline_Marker 作为自定义实体类型

## MCP Server 集成

```
Rust 知识库 → MCP Server → Claude Code
     ↓
   mem-search skill
```

### 与现有 kb-rust 的接口

```rust
// kb-rust 作为 MCP Server 运行
// 提供工具：
// - kb_search: 分层检索
// - kb_timeline: 时间上下文
// - kb_get: 获取完整详情
// - kb_ingest: 注入新观察
```

## 集成计划

| 时间 | 任务 |
|------|------|
| 本周 | 研究 kb-rust 三层索引设计 |
| 下周 | 实现 PostToolUse 钩子触发蒸馏 |
| 下月 | 接入 qmd 混合搜索增强 kb-rust |

## 已知限制

- AGPL-3.0 许可证（开源但需公开修改）
- 需要 Bun + Node.js 环境
- 作为参考实现，不直接集成

