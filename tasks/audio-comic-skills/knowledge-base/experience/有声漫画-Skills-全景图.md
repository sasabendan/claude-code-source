---
name: 有声漫画 Skills 全景图
entry_type: experience
created: 2026-04-26T00:40:31.000000+00:00
updated: 2026-04-26T00:40:31.000000+00:00
tags: [skills,overview,全景图,角色分工,监工]
status: stable
---

# 有声漫画 Skills 全景图

> 版本：1.1 | 更新：2026-04-26
> 用途：监工（Claude）掌握所有角色分工，便于价值观判断和优先级决策

---

## 主线任务

**多AGI无监督自动化有声漫画生产**

起点 = 原著小说 → 输出 = 有声漫画产品

---

## 角色分工（三类）

### 一、生产技能（5个，流水线执行）

| Skill | 负责环节 | 触发词 | 依赖 |
|-------|---------|--------|------|
| [[audio-comic-workflow]] | 7环节流水线编排，断点续跑 | 「开始创作有声漫画」 | 其他所有 Skill |
| [[comic-style-consistency]] | 画风锚定、声音一致性、风格校验 | 「生成角色」「保持画风」 | 经验库 |
| [[supervision-anti-drift]] | 监督验收、漂移检测、NCA 阻断 | 自动包裹，无需触发 | 所有生产环节 |
| [[self-optimizing-yield]] | 良品率追踪、反馈闭环、调优回路 | 每批次结束自动触发 | 良品率数据 |
| [[knowledge-base-manager]] | 知识库管理、增量Wiki、Obsidian双链 | 「查询知识库」等 | Biji API（远期） |

### 二、元技能（5个，AI 行为规范）

| Skill | 职责 | 触发时机 |
|-------|------|---------|
| [[claude-scope-judge]] | 范围判定，红灯/绿灯通行 | 不确定是否在授权范围内时 |
| [[claude-first-check]] | 先查再动，7步检查顺序 | 任何工作要求的第一动作 |
| [[claude-error-handler]] | C17→C19→C20→C23 强制链条 | 遇到错误/不理解/不合理时 |
| [[claude-memory]] | 记忆存取，Keychain，授权管理 | 密码/API Key/配置路径 |
| [[claude-values]] | 价值观判断，知识库价值层级 | 「什么重要」「该不该做」时 |

### 三、工具技能（9个，辅助支撑）

| Skill | 用途 |
|-------|------|
| [[claude-usage]] | Claude 用量追踪，成本计算 |
| [[claude-usage-monitor]] | Claude 额度监控，配额优化 |
| [[minimax-usage]] | MiniMax Token Plan 用量（5h/24h 周期） |
| [[core-asset-protection]] | 核心资产保护，备份模型执行（HC-AP1/2/3） |
| [[encrypted-backup]] | AES-256 加密备份，GitHub 并行备份 |
| [[claude-export-markdown]] | Claude 回复导出 Markdown |
| [[claude-cite-reference]] | 引用标记，@ref: 展开 |
| [[claude-file-safety]] | 文件删除安全判定 |
| [[task-book-keeper]] | 任务书管理，核心记忆保留 |

---

## 约束体系（C0-C23）

### 硬约束（禁止违反）

| 约束 | 内容 |
|------|------|
| **禁止自动删除** | 知识库管理的文件，不得自动请求删除（User 主动要求除外） |
| [[encrypted-backup]] | GitHub 备份加密；本地永远保留明文（两者并行，非替代） |
| C11 | 本地备份不加密，做好版本管理；GitHub 备份必须加密 |
| C17 | 查询顺序：任务书→知识库→上下文→技能→备份→网络 |
| C19 | 发现违规立即记录到 .index.jsonl + 修复，不问用户 |
| C20 | 错误范例关键词 ≠ 修改约束依据 |
| [[claude-error-handler]] | C17→C19→C20→C23 强制链条执行 |
| C23 | C17 走完仍无解 → 补技能/知识，不改约束 |

### 流程约束

| 约束 | 内容 |
|------|------|
| C15 | 分叉完成后必须回到主线 |
| [[claude-first-check]] | 3分钟无动作则自检，继续主线（C18） |

### 工具约束

| 约束 | 内容 |
|------|------|
| [[supervision-anti-drift]] | openspec==0.21.0 **锁定**，v1.0+ 破坏 Skills 触发链路 |

### 项目级约束

| 约束 | 内容 | 关系 |
|------|------|------|
| **禁止自动删除** | 知识库管理的主任务文件不得自动请求删除 | FC004 根因补救：删除核心资产前必须 C17 查询 |
| **C-DEV** | 测试目录（knowledge-base-test/ + kb-v2-test/）禁止并入生产 KB | 独立于 C0-C23，无冲突；与 C17/C19 中的 production `.index.jsonl` 不重叠 |

> 禁止自动删除详细说明：[[claude-file-safety]] | FC004 根因分析：[[claude-error-handler]]
> C-DEV 详细说明：[[C-DEV 项目目录约束]]（含与 C0-C23 关系）

---

## 当前优先级（监工判断）

### P0（基建，必须先做）

- ✅ kb-rust v2 基建稳定化（add/ingest auto-rebuild）
- 🔄 WORKFLOW.md 双链标准落实（逐步补 [[wikilinks]]）

### P1（核心链路，依赖 P0）

- ⏳ 补全双链 → Obsidian 图谱"生长"
- ⏳ init 对已有库幂等补全
- ⏳ Biji API 实际接入（sync-biji 完整实现）

### P2（增强功能）

- ⏳ plot-template 命令（分镜输入标准化）
- ⏳ yield-stats 命令（良品率统计）

### 暂缓（R11/yield-stats-真实现/plot-template/sync-biji 真实现）

> 以上均依赖：入口稳定 + 编译一致 + 可视化可用

---

## 监工视角：已知完成度

| 维度 | 状态 | 说明 |
|------|------|------|
| kb-rust 工具链 | ✅ v2.1.1 就绪 | 14 命令，auto-rebuild 生效 |
| 知识库入口 | ✅ 总条目 59 条 | _index.md 和 .index.jsonl 同步 |
| 双链图谱 | ⚠️ 1 backlink target | 页面无 [[wikilinks]]，待补 |
| Skills 全景图 | ✅ 19 条 KB 条目 | 本文档 |
| 备份机制 | ✅ HC-AP1/2/3 + encrypted-backup | 核心资产保护体系（FC004 后加固） |
| 良品率闭环 | ❌ 未实际运行 | 依赖生产流水线真实运转 |

---

## 文档管理规则

- 所有 Skills 文档 → [[knowledge-base-manager]] 索引（KB 管理）
- 项目管理文件（SPEC/CHANGELOG） → `~/.backup/audio-comic-skills/kb-rust/archive/`
- 当前工作版本 → `kb-rust/v2/` 项目目录
- 迁移记录 → [[kb-rust 归档迁移记录]]
