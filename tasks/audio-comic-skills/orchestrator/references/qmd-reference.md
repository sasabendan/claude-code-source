# qmd 技术参考

> 来源：https://github.com/tobi/qmd
> 学习时间：2026-04-30
> 相关性：混合搜索、Context Tree、本地 GGUF 模型

## 核心设计

### 混合搜索 SOTA 管线

```
查询 → LLM 扩展 → [原始查询 × 2] + [变体1] + [变体2]
                ↓
        BM25 + Vector 并行检索
                ↓
        RRF 融合（k=60）
                ↓
        Top 30 → LLM 重排
                ↓
        Position-Aware Blend：
        1-3名：75% RRF + 25% reranker
        4-10名：60% RRF + 40% reranker
        11名+：40% RRF + 60% reranker
```

**关键算法**：RRF (Reciprocal Rank Fusion)
```python
score = Σ(1 / (k + rank + 1))
# k=60，顶名加成 +0.05（#1）, +0.02（#2-3）
```

### Context Tree（树状上下文）

```bash
# 关键功能：自动注入层级背景
qmd context add qmd://docs "REST API reference documentation"
qmd context add qmd://notes "Personal notes and ideas"

# 检索时自动返回：
# doc + context（层级背景）
```

**借鉴意义**：世界线收束模型
- 每条世界线 → Collection
- 核心收束点 → Root Context
- AI 读取任何一条线时，自动获得"收束目标"感知

### 本地性能优化

| 模型 | 用途 | 大小 |
|------|------|------|
| embeddinggemma-300M | 向量化 | ~300MB |
| qwen3-reranker-0.6B | 重排 | ~640MB |
| qmd-query-expansion-1.7B | 查询扩展 | ~1.1GB |

**显存管理**：5 分钟闲置释放 + 按需重建

### MCP Server

```json
// 配置
{
  "mcpServers": {
    "qmd": {
      "command": "qmd",
      "args": ["mcp"]
    }
  }
}
```

暴露工具：query / get / multi_get / status

## 与现有资产的接口

```
kb-rust（已有）
  ↓
qmd 混合搜索（参考）
  → RRF 融合算法 → 升级 kb-rust 检索
  → Context Tree → 集成到 knowledge-base-manager
  
audio-orchestrator（已有）
  ↓
qmd MCP Server（新增）
  → 作为外部搜索后端
```

## 集成计划

| 时间 | 任务 |
|------|------|
| 本周 | 研究 qmd RRF 融合算法 |
| 下周 | 集成 Context Tree 到 S1 knowledge-base-manager |
| 下月 | 考虑 qmd 作为 MCP Server 替代方案 |

## 已知限制

- Node.js 22+ / Bun 1.0+ 环境
- 作为参考实现
- 本地 GGUF 模型占用 ~2GB 磁盘

