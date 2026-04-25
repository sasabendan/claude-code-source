---
type: style
name: 多服务商图像生成 API 矩阵
created: 2026-04-25T02:55:35Z
tags: [api, image, provider, minimax]
---

## 多服务商图像生成 API 矩阵

### 定位
S2 和 S3 生图环节的 API 选择决策参考。

### 服务商一览

| 服务商 | 模型 | 擅长场景 | 参考图 | 中文化 |
|--------|------|---------|--------|--------|
| OpenAI | gpt-image-2 | 通用、高质量 | 支持 | 一般 |
| Google | gemini-3-pro-image | 细节、摄影感 | 支持 | 一般 |
| 阿里通义万相 | qwen-image-2.0-pro | 海报、中英文排版 | 不支持 | **最佳** |
| Z.AI GLM | glm-image | 海报、图表 | 不支持 | **最佳** |
| MiniMax | image-01 | 人像一致性 | subject_ref | 一般 |
| 即梦 Jimeng | jimeng_t2i_v40 | 中国风 | 不支持 | **最佳** |
| 豆包 Seedream | seedream-5.0 | 文字排版 | 支持 | **最佳** |

### 选择策略
- **有中文文字要求** → 通义万相 / Z.AI / 即梦 / 豆包
- **角色一致性要求高** → MiniMax subject_reference
- **通用高质量** → OpenAI / Google
- **成本优先** → Replicate nano-banana

### 原文位置
`reference-05-baoyu-skills.md` → baoyu-imagine

