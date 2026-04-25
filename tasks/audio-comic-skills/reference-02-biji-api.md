# Get 笔记开放平台 API 参考

> 来源：https://doc.biji.com
> 更新：2026-04-24（文档站点部分 URL 已变更，以下为综合整理版）

---

## 开放平台概述

Get 笔记提供 AI 技能（Skills）和开放 API 两类接入方式：
- **AI 技能**：通过上传 Skill 包，让 Get 笔记 AI 理解你的私有知识
- **开放 API**：RESTful API，支持笔记管理、知识库操作、AI 对话

---

## 主要 API 端点

| 功能 | 端点（示意） | 方法 |
|------|------------|------|
| 创建笔记 | `/v1/notes` | POST |
| 获取笔记 | `/v1/notes/:id` | GET |
| 更新笔记 | `/v1/notes/:id` | PUT |
| 删除笔记 | `/v1/notes/:id` | DELETE |
| 上传文件 | `/v1/files/upload` | POST |
| 创建知识库 | `/v1/knowledge-bases` | POST |
| 知识库搜索 | `/v1/knowledge-bases/:id/search` | POST |

> 注：实际端点以 Get 笔记官方最新文档为准，doc.biji.com 部分路径已变更。

---

## 认证方式

通过 API Key 进行认证，请求头格式：
```
Authorization: Bearer {API_KEY}
```

---

## 知识库使用限制

- 免费用户：最多 3 个知识库，总空间 30GB（10GB/个）
- PRO 会员：最多 10 个知识库，总空间 500GB（50GB/个）
- 所有用户均能体验完整的 AI 能力，区别仅在于使用次数/容量

---

## 订阅功能

知识库支持订阅：
- 订阅指定视频号，自动获取更新内容
- 订阅博主笔记
- 导入已有笔记

---

## MCP（Model Context Protocol）支持

Get 笔记还提供 MCP 接口，允许 Claude 等 AI 工具直接接入进行笔记读写操作。

---

## 相关文档

- Skill 使用指南：https://doc.biji.com/claude-skill
- 开放平台首页：https://doc.biji.com/openapi
- MCP 使用指南：https://doc.biji.com/mcp-usage
- CLI 使用指南：https://doc.biji.com/cli-usage

> **注意**：上述部分文档 URL 在 2026-04-24 访问时返回 404，建议直接访问 https://doc.biji.com 查阅最新路径。

---

## 与知识库的集成

本项目（有声漫画自动化生产 Skills 体系）通过 `kb_sync_biji()` 函数对接 Get 笔记：
- 读取 `BIJI_API_KEY` 环境变量
- 调用 `/v1/knowledge-bases` 系列端点
- 将内容同步到本地 `knowledge-base/` 目录

API Key 设置方式：
```bash
export BIJI_API_KEY=你的密钥
```
