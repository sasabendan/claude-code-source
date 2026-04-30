---
name: API Key 安全规格
entry_type: experience
created: 2026-04-27T00:00:00.000000+00:00
updated: 2026-04-27T00:00:00.000000+00:00
tags: [API-Key,安全规格,密钥管理,HC-API1,HC-API2,HC-API3,禁止外泄]
status: stable
---

# API Key 安全规格

> 版本：1.0 | 创建：2026-04-27
> 定位：所有 API Key / Token / 密码的安全管理规格
> 适用于：Skills、脚本、MCP 配置、知识库条目

---

## 核心约束（HC-API 硬约束）

> **最高优先级，不得违反。违反即触发 [[claude-error-handler]] C17→C19→C23 链条。**

### HC-API1：禁止远程备份
API Key 不得推送到任何远程服务器（GitHub / 云存储 / 第三方服务）。

**适用范围**：
- GitHub 仓库（任何分支、任何 commit）
- 加密备份中的 .enc 文件（禁止将 Key 写入 .enc）
- 云同步服务（iCloud / Dropbox / Google Drive）
- 第三方服务 API 请求体中（除必要调用外）

**例外**：用户主动、明确提供 Key 并要求配置时，按用户指令执行。

### HC-API2：禁止复制或传输
API Key 不得在未授权的情况下复制、粘贴、导出到其他文件或工具。

**适用范围**：
- 跨文件复制（即使在同一机器内）
- 跨机器传输（任何网络手段）
- 通过 API 调用传输到第三方
- 写入日志、输出、markdown 内容

**例外**：用户主动要求时，按用户指令执行。

### HC-API3：禁止删除
已存储的 API Key 不得自动删除。

**适用范围**：
- 不得自动修改 `config.local.json` 中的 Key
- 不得删除 `~/.backup-password` 等密钥文件
- 不得清空 Keychain 条目

**例外**：用户主动、明确要求删除时，执行删除并记录到 .index.jsonl fail-case 条目。

### HC-API4：修改必须用户授权
所有 Key 相关操作（配置、更新、删除）必须获得用户明确授权。

**触发条件**：
- 新增 Key 存储 → 用户主动提供并授权存储
- 更新 Key → 用户主动提供新 Key 并授权更新
- 删除 Key → 用户明确要求删除

**操作流程**：
```
用户主动提供 Key
    ↓
Claude 确认存储路径（.local.json / Keychain / ~/.backup-password）
    ↓
执行存储
    ↓
记录到知识库（API Key 安全规格 KB 条目，不含实际 Key 值）
    ↓
完成
```

---

## 已知 Key 清单（不含实际值）

| Key 名称 | 类型 | 存储路径 | 用途 | 状态 |
|---------|------|---------|------|------|
| 备份密码 | 密码 | `~/.backup-password` | GitHub 加密备份 | ✅ 已配置 |
| Exa API Key | API Key | `~/.claude/skills/exa-search/config.local.json` | 网络搜索（MCP） | ✅ 已配置 |
| Serper API Key | API Key | `~/.claude/skills/serper-search/config.local.json` | 网络搜索 | ✅ 已配置 |
| MiniMax API Key | API Key | 待确认 | 图像生成 / TTS | ⏳ 待配置 |

---

## Key 存储规范

### 允许的存储路径

| 路径类型 | 示例 | 适用场景 |
|---------|------|---------|
| `config.local.json`（.gitignore 保护） | `~/.claude/skills/<skill>/config.local.json` | Skills 专用配置 |
| `~/.backup-password`（chmod 600） | `~/.backup-password` | 备份加密密码 |
| macOS Keychain | `security find-generic-password` | 长期存储、脚本读取 |
| 环境变量（会话级） | `export EXA_API_KEY=...` | 临时验证 |

### 禁止的存储路径

| 路径类型 | 原因 |
|---------|------|
| GitHub 任何文件 | HC-API1 |
| 知识库任何文件 | HC-API1 |
| 日志文件 | HC-API2 |
| Markdown 内容正文 | HC-API2 |
| 加密备份 .enc | HC-API1（Key 不写入备份流） |

### config.local.json 保护规则

```
skills/<name>/config.local.json
    ↓ 必须加入 .gitignore
*.local.json
```

---

## 与 Skills 的连接

| Skill | Key 相关职责 |
|-------|------------|
| [[claude-memory]] | Keychain 读写，密码/Key 存储方案 |
| [[core-asset-protection]] | HC-AP3 扩展：API Key 纳入核心资产范围 |
| [[encrypted-backup]] | 加密时禁止将 Key 写入备份流 |
| [[claude-error-handler]] | HC-API 违规 → C17→C19→C20→C23 链条 |

---

## 版本历史

### v1.0 (2026-04-27)
- 初始版本：API Key 安全规格建立
- HC-API1/2/3/4 约束体系确立
- 已知 Key 清单建立（4项，含 Exa + Serper）
- 与现有 Skills 建立连接
