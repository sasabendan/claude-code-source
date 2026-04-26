# kb-rust 参考项目文档

> 建立时间：2026-04-24
> 用途：记录所有 KB 相关的参考项目，供用户确认设计方向后重新梳理功能

---

## 一、任务书设立时确立的参考项目

### 网络参考来源（TASK_REQUIREMENTS.md 参考资料清单）

| # | 来源 | URL | 状态 | 本地存放 |
|---|------|-----|------|---------|
| 1 | Claude Skills 开发指南（sanshao85） | `github.com/sanshao85/claude-skills-guide` | ✅ 已抓取 | `reference-01-claude-skills-guide.md` |
| 2 | 得到笔记 API | `doc.biji.com` + `biji.com/openapi` | ✅ 部分抓取 | `reference-02-biji-api.md` |
| 3 | rosetears Supervisor-Worker 框架 | `rosetears.cn/archives/85/` | ✅ 已抓取 | `reference-03-rosetears-85.md` |
| 4 | rosetears 进阶 | `rosetears.cn/archives/55/` | ✅ 已抓取 | `reference-04-rosetears-55.md` |
| 5 | baoyu-skills（JimLiu） | `github.com/JimLiu/baoyu-skills` | ✅ 已抓取 | `baoyu_skills_full.md` |
| 6 | OpenSpec v0.21 vs v1.0 | `github.com/Fission-AI/OpenSpec/issues/630` | ✅ 已抓取 | `reference-06-openspec-630.md` |

### GitHub Stars 参考项目（TASK_REQUIREMENTS.md GitHub可用Skills）

| # | 仓库 | ⭐ | 对应 | 状态 |
|---|------|---|------|------|
| G1 | `Astro-Han/karpathy-llm-wiki` | 605 | S1 | ✅ 下载说明存于 experience/downloaded_*.md，未读源码 |
| G2 | `eugeniughelbur/obsidian-second-brain` | 271 | S1/S6 | SKILL.md 引用，无本地文件 |
| G3 | `JimLiu/baoyu-skills` | 16,273 | S2/S3/S6 | ✅ 已抓取存为 baoyu_skills_full.md |

---

## 二、用户指定的 3 个参考项目（需 fetch 源码学习）

### 1. nashsu/llm_wiki
- **URL**: `https://github.com/nashsu/llm_wiki`
- **状态**: 未 fetch，从未阅读源码
- **需做**: fetch 后分析其功能设计

### 2. lucasastorian/llmwiki
- **URL**: `https://github.com/lucasastorian/llmwiki`
- **状态**: 未 fetch，从未阅读源码
- **需做**: fetch 后分析其功能设计

### 3. karpathy/llm-wiki（gist）
- **URL**: `https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f`
- **状态**: 未 fetch，从未阅读源码
- **需做**: fetch 后分析其功能设计

---

## 三、原始 KB 设计需求（从任务书提取）

### TASK_REQUIREMENTS.md Skill 1 设计要求

```
功能定位：本地知识库管理 — 原著细节、世界观、角色设定记录
核心能力：
  ① 得到笔记 OpenAPI（网络源）
  ② GitHub（备份源）
  ③ 增量式 Wiki 架构
  ④ Obsidian 双链格式
参考来源：① 得到笔记 API ② Astro-Han/karpathy-llm-wiki ③ eugeniughelbur/obsidian-second-brain
```

### 第一版 bash 实现（skills/knowledge-base-manager/scripts/kb-manager.sh）

**架构**：
```
knowledge-base/
├── .index.jsonl          # 单一索引（JSONL，每行一条）
├── characters/          # 角色设定
├── world/               # 世界观
├── plot/                # 剧情细节
├── styles/              # 风格参数
├── voices/              # 配音设定
└── experience/          # 经验知识
```

**frontmatter 字段**：`type`, `name`, `created`, `tags`
**JSONL 字段**：`type`, `name`, `file`, `tags`, `created`
**Obsidian 兼容**：`tags: [tag1,tag2]`（YAML 数组格式）

**未实现功能**：
- kb_sync_biji() = 空 stub，从未调用真实 API
- 无向量/Embedding 搜索
- 无 Obsidian 双向链接 `[[链接]]` 解析
- 无需求文档（设计决策散见于 TASK_REQUIREMENTS.md + SKILL.md）

---

## 四、当前 kb-rust 实现状态

| 命令 | 状态 | 说明 |
|------|------|------|
| init | ✅ | 创建目录 + 空 .index.jsonl |
| add | ✅ | 生成 Markdown + 追加 .index.jsonl |
| list | ✅ | 按类型统计 |
| query | ✅ | 按类型查询 |
| search | ✅ | 名称/标签全文搜索（大小写不敏感） |
| rebuild | ✅ | 从 Markdown frontmatter 重建索引 |

**frontmatter 解析**：
- `name:` 行 → 条目名称（优先）
- `# 标题` 行 → 备选（无 frontmatter 时）
- `tags:` 行 → 解析 YAML 数组 `[a,b]` 和逗号分隔格式
- `created:` 行 → RFC3339 时间戳
- `entry_type` → 由 Markdown 文件所在目录推断

**已知限制**：
- 全量文本扫描，>10000 条性能下降
- rebuild 依赖 Markdown 文件存在，文件丢失则索引不更新
- JSONL 字段名已统一为 `entry_type`（36 条全部一致）

---

## 五、参考项目抓取状态总览

```
✅ 已抓取（可本地查阅）：
  - reference-01-claude-skills-guide.md    (~2500行，完整 Claude Skills 指南)
  - reference-02-biji-api.md               (API 端点说明，待完整)
  - reference-03-rosetears-85.md           (Supervisor-Worker 框架)
  - reference-04-rosetears-55.md            (进阶用法)
  - baoyu_skills_full.md                   (16k ⭐ baoyu-skills 全文)
  - reference-06-openspec-630.md           (OpenSpec GitHub Issue)
  - knowledge-base/experience/downloaded_* (openspec/codex 操作手册)

⚠️ 已引用但未阅读源码：
  - Astro-Han/karpathy-llm-wiki             (605 ⭐，存了下载说明，未读源码)
  - eugeniughelbur/obsidian-second-brain    (271 ⭐，SKILL.md 提到，无本地文件)
  - nashsu/llm_wiki                         (用户指定，未 fetch)
  - lucasastorian/llmwiki                   (用户指定，未 fetch)
  - karpathy gist (442a6bf5...)             (用户指定，未 fetch)
```

---

## 六、待确认的功能方向（未开始）

| 功能 | 需求来源 | 当前状态 |
|------|---------|---------|
| Biji API 同步 | TASK_REQUIREMENTS.md Skill 1 | kb_sync_biji() stub |
| 向量/Embedding 搜索 | SKILL.md 提到"自动化向量图" | 未实现 |
| Obsidian Vault 可视化 | SKILL.md | 未实现 |
| Obsidian 双向链接 `[[链接]]` 解析 | SKILL.md | 未实现 |
| GetBiji API 完整调用 | reference-02-biji-api.md | 未实现 |

---

## 三、用户提供的补充参考（2026-04-25 新增）

### 新增参考文章（PDF，原文已存档）

| # | 标题 | 来源 | 日期 | 本地路径 |
|---|------|------|------|---------|
| A1 | Obsidian从1到2：搭建可自我进化的AI全自动化内容创作工作流 | Get笔记（微信） | 2026-04-24 | `knowledge-base/reference-articles/A1_*.pdf` + `.txt` |
| A2 | Obsidian + AI 构建动态智能系统：从静态 Wiki 到自我进化的第二大脑 | Get笔记（微信） | 2026-04-26 | `knowledge-base/reference-articles/A2_*.pdf` + `.txt` |

> 这两篇是本项目**最重要的原始参考**——直接展示了"起点=原著，输出=AI漫画"的完整案例，解释了连接 GetBiji 的核心目的。

### A1/A2 核心设计要点（提炼）

| 要点 | 原文 | 对应需求 |
|------|------|---------|
| 中央大脑 | "创建统一的工作流说明书作为项目中央大脑，AI开工前必须先阅读" | R1 工作流说明书 |
| 角色锁定 | "单独创建人物形象文件夹，创作前必须调用指定形象" | R2 角色状态管理 |
| 剧情分解标准化 | "每章包含页码、概述、出场人物、场景描述（地点/对话/分镜建议）" | R3 剧情分解 |
| 双链联动 | "所有文件设置双链，实现人物-剧情-场景联动" | R4 双链索引 |
| 反馈优化循环 | "第一回50%→第四回70%，成本30刀→<10刀" | R5 反馈记录 |
| 版本控制 | "AI批量处理文件的能力越强，越需要版本控制来兜底" | R6 Git辅助 |
| 知识库即系统 | "本地知识库不再是静态Wiki，而是可自主调用的活系统" | 整体架构目标 |

### GetBiji 连接的核心目的

原文明确回答：
> "起点仅为一份原著 PDF，最终实现 AI 对创作标准的完全理解。"

连接 GetBiji 不是为了"同步笔记"，而是为了：
1. **自动化获取**：原著更新 → 自动推送到本地知识库
2. **AI训练素材**：持续对话让AI理解用户的风格/标准/审美
3. **多端同步**：Obsidian + GetBiji + AI → 跨设备一致

---

## 四、所有参考项目完整清单（最终版）

```
网络来源（Task Requirements 确立）：
  ✅ 1.  sanshao85/claude-skills-guide    → reference-01-claude-skills-guide.md
  ✅ 2.  doc.biji.com API                 → reference-02-biji-api.md
  ✅ 3.  rosetears.cn/85 (Supervisor)      → reference-03-rosetears-85.md
  ✅ 4.  rosetears.cn/55 (进阶)           → reference-04-rosetears-55.md
  ✅ 5.  JimLiu/baoyu-skills (16k⭐)       → baoyu_skills_full.md
  ✅ 6.  Fission-AI/OpenSpec#630           → reference-06-openspec-630.md

GitHub Stars（Task Requirements 引用）：
  ⚠️ G1. Astro-Han/karpathy-llm-wiki      (605⭐) 存下载说明，未读源码
  ⚠️ G2. eugeniughelbur/obsidian-second-brain (271⭐) 仅 SKILL.md 引用，无本地文件
  ✅ G3. JimLiu/baoyu-skills              (16k⭐) 已抓取全文

用户指定（2026-04-25 新增）：
  ⚠️ nashsu/llm_wiki                     未 fetch 源码
  ⚠️ lucasastorian/llmwiki               未 fetch 源码
  ⚠️ karpathy gist (442a6bf5...)         未 fetch 源码

微信参考文章（2026-04-25 新增）：
  ✅ A1. Obsidian从1到2（小李飞刀案例）     PDF+txt 已存档
  ✅ A2. Obsidian+AI 第二大脑              PDF+txt 已存档
```

✅ = 可本地查阅  ⚠️ = 待 fetch

---

## 五、三个参考项目核心设计发现（v2 开发用）

### 5.1 Karpathy 原版方法论（原始设计模式）

**文件**：`/tmp/ref_karpathy_gist.md`（11673 chars，已提取）

**三层架构**：

| 层 | 说明 | 本项目对应 |
|---|------|-----------|
| **Raw Sources** | 上传文档（不可变），LLM 只读 | `knowledge-base/experience/` 等目录下的原始文件 |
| **Wiki** | LLM 生成和维护的 Markdown 文件集合 | AI 通过 add/rebuild 生成的条目 |
| **Schema** | CLAUDE.md/AGENTS.md，告诉 LLM 工作规范 | `CLAUDE.md` + 各 Skill SKILL.md |

**三个核心操作**：

| 操作 | Karpathy 定义 | 本项目当前实现 |
|------|--------------|--------------|
| **Ingest** | LLM 读源文件 → 更新/创建多个 Wiki 页面 → 更新 index/log | ⚠️ 部分实现（add 单条，缺多页面联动） |
| **Query** | LLM 读 index → 读相关页面 → 综合回答 → 有价值答案归档为新页面 | ⚠️ 部分实现（search 文本搜索，无 index 优先） |
| **Lint** | 健康检查：矛盾/孤立页面/缺失交叉引用/过时声明 | ❌ 未实现 |

**两个特殊文件**：

```
index.md  — 内容目录，每条含链接+一行摘要+元数据，按类别组织
           LLM 回答问题前先读 index 找相关页面（~100源/数百页面规模无需向量）
log.md    — 时序记录，追加写入，每条格式一致 "## [YYYY-MM-DD] ingest|query|lint"
           可用 grep "^## \[" log.md | tail -5 解析
```

**Karpathy 原文关键句**：
> "Obsidian is the IDE; the LLM is the programmer; the wiki is the codebase."
> "You never (or rarely) write the wiki yourself — the LLM writes and maintains all of it."
> "The wiki is a persistent, compounding artifact."

---

### 5.2 nashsu/llm_wiki（桌面增强版）

**文件**：`/tmp/ref_nashsu_llm_wiki/README_CN.md`（完整中文 README）

**核心增强**（超出 Karpathy 的部分）：

| 增强 | 内容 | v2 参考 |
|------|------|--------|
| **purpose.md** | 定义 Wiki 的"为什么"：目标/关键问题/研究范围/演进论点。LLM 每次摄入和查询都读 | R1 工作流说明书相关 |
| **两步思维链摄入** | 第一步：LLM 分析（关键实体/矛盾/结构建议）→ 第二步：基于分析生成 Wiki 文件 | 可对应"剧情分解"步骤 |
| **四信号知识图谱** | 直接链接×3 + 来源重叠×4 + Adamic-Adar×1.5 + 类型亲和×1 | R4 双链索引相关 |
| **Louvain 社区检测** | 自动发现知识聚类，内聚度评分，孤立页面检测 | R4 图谱分析 |
| **向量搜索（可选）** | LanceDB（Rust 嵌入式），任意 OpenAI 兼容端点，关闭时 fallback 到分词+图谱 | R10 远期 |
| **增量缓存** | SHA256 检查源文件，未变则跳过 | 性能优化参考 |
| **多格式文档** | PDF/DOCX/PPTX/XLSX/图片/视频/音频，结构化提取 | T1 痛点解决方向 |

**项目结构（nashsu）**：

```
my-wiki/
├── purpose.md              # 目标/关键问题/研究范围（新增）
├── schema.md               # Wiki 结构规则（对应 Schema 层）
├── raw/sources/            # 原始文档（不可变）
├── wiki/
│   ├── index.md            # 内容目录
│   ├── log.md              # 时序记录
│   ├── overview.md         # 全局概要（自动更新）
│   ├── entities/           # 人物/组织/产品
│   ├── concepts/           # 理论/方法/技术
│   ├── sources/            # 资料摘要
│   ├── queries/            # 保存的问答
│   └── synthesis/          # 跨资料分析
└── .llm-wiki/              # 应用配置/聊天/审核项
```

---

### 5.3 lucasastorian/llmwiki（完整 Web 应用）

**文件**：`/tmp/ref_lucasastorian_llmwiki/`（Next.js + FastAPI + Supabase + MCP）

**MCP 工具设计**（5个核心工具）：

| 工具 | 功能 | 本项目参考 |
|------|------|-----------|
| `guide` | 解释 Wiki 架构 + 列出可用知识库 | 当前 `--help` 近似，未结构化 |
| `search` | list（浏览文件）或 search（PGroonga 关键词排名） | v1 有 search，缺浏览模式 |
| `read` | 读文档（PDF 含页码范围）/glob 批量读/内联图片 | ⚠️ 当前只读 index.jsonl，未读实际 MD 内容 |
| `write` | 创建/编辑/追加 Wiki 页面，支持 SVG/CSV | add 已实现，缺 str_replace 编辑 |
| `delete` | 按路径或 glob 模式归档文档 | 缺 delete 命令 |

**Wiki 页面写作规范（guide.py 中定义）**：

```
必需结构：
- 第一段：摘要（无 H1，标题由 UI 渲染）
- ## 大章节，### 子章节
- 每个页面必须含至少一个视觉元素：
  - Mermaid 图表：流程/时序/矩阵/ER图
  - 表格：特征对比/时间轴/指标
  - SVG 资产：Mermaid 无法表达的复杂图

引用规范：
- 每个事实声明必须标注来源脚注
- 格式：[^1]: filename.pdf, p.3
- 完整文件名，含页码
```

**lucasastorian Wiki 结构**：

```
/wiki/overview.md          # 总览：源数量/页面数/关键发现/最近更新
/wiki/concepts/           # 抽象概念：理论/方法/主题
/wiki/entities/           # 具体实体：人/组织/产品/技术/论文/数据集
/wiki/log.md              # 时序记录：ingest/query/lint 条目
/wiki/comparisons/        # 并列对比（如 x-vs-y.md）
```

---

### 5.4 三项目设计要点汇总（对比）

| 设计点 | Karpathy 原版 | nashsu 增强 | lucasastorian 实现 | 本项目 v1 |
|--------|--------------|------------|------------------|---------|
| 层级架构 | 3层（Raw/Wiki/Schema） | 3层+purpose.md | 3层（Supabase DB） | 3层（目录/JSONL/SKILL.md） |
| Ingest | 手动/单条 | 两步思维链+队列 | MCP write | add 单条 |
| Query | index 优先 | 分词+图谱+向量 | MCP search | search 文本 |
| Lint | 定期检查 | 自动图谱洞察 | - | ❌ |
| index.md | 必需，内容目录 | 必需 | overview.md | ❌ |
| log.md | 必需，时序记录 | 必需 | log.md | ❌ |
| purpose.md | - | ✅ 新增 | - | ❌（可对应工作流说明书） |
| 双链语法 | `[[wikilinks]]` | `[[wikilinks]]` | `[[wikilinks]]` | 未解析 |
| frontmatter | ✅ YAML | ✅ YAML | ✅ YAML | ✅ |
| Obsidian 兼容 | ✅ | ✅（生成.obsidian/） | ✅ | ⚠️ 兼容（标签格式） |
| 向量搜索 | - | ✅ 可选 LanceDB | - | ❌ |
| 视觉元素要求 | - | - | ✅ 每页必须有 Mermaid/表格 | ❌ |
| MCP 工具 | - | - | ✅ guide/search/read/write/delete | ❌ |
| 多格式文档 | - | ✅ PDF/DOCX/PPTX | ✅ | ❌（仅 MD） |

---

## 六、用户提供的原始文件（2026-04-25 补充）

| 文件 | 内容 | 本地路径 |
|------|------|---------|
| `llmwiki.md`（桌面，原文件） | GitHub Gist HTML 页面，519KB（包含 CSS/JS） | `knowledge-base/experience/karpathy_llm_wiki_original.md`（清理后 11,742 字节） |

**清理后版本**：`/tmp/llmwiki_raw.md`（纯 Markdown，11,742 chars，已复制到知识库）
**关键**：用户提供的桌面文件与之前从 GitHub fetch 的版本内容一致，均为 Karpathy 原文，无差异。

---

## 七、设计依赖层级（最终确认）

```
原始方法论（Karpathy llm-wiki.md）
  ├── 三层架构：Raw Sources / Wiki / Schema
  ├── 三个核心操作：Ingest / Query / Lint
  ├── 两个特殊文件：index.md（内容目录） + log.md（时序记录）
  ├── [[wikilinks]] 双链语法
  ├── YAML frontmatter
  ├── Obsidian 兼容（直接作为 Obsidian 仓库）
  ├── 人类策展，LLM 维护（核心角色分工）
  └── "The wiki is a persistent, compounding artifact."
         │
         ├──→ nashsu/llm_wiki（桌面应用）
         │      ├── purpose.md（新增）
         │      ├── 两步思维链摄入
         │      ├── 四信号知识图谱
         │      ├── Louvain 社区检测
         │      ├── 可选向量搜索（LanceDB）
         │      └── 多格式文档支持
         │
         ├──→ lucasastorian/llmwiki（Web+MCP）
         │      ├── MCP 工具：guide/search/read/write/delete
         │      ├── Supabase PostgreSQL + PGroonga 搜索
         │      ├── Next.js 前端 + FastAPI 后端
         │      └── Wiki 写作规范（视觉元素+引用必需）
         │
         ├──→ A1/A2（微信，小李飞刀案例）
         │      ├── 工作流说明书.md（中央大脑）
         │      ├── 人物形象文件夹（锁定+调用）
         │      ├── 剧情分解标准化
         │      ├── 反馈优化循环（50%→70%）
         │      ├── 版本控制（10分钟自动备份）
         │      └── "起点=原著 PDF，AI 完全理解创作标准"
         │
         └──→ kb-rust v2（我们）
                ├── 三层架构（Raw/Wiki/Schema）
                ├── Ingest-Query-Lint 完整操作
                ├── _compiled/_index.md + _compiled/_log.md
                ├── WORKFLOW.md（Schema 层，对应 purpose.md）
                ├── 双链索引（_backlinks.json）
                ├── 角色状态管理（stable/wip/retired）
                ├── Biji API 同步（sync-biji）
                ├── 良品率追踪（yield-stats）
                └── 项目元数据隔离（.project.json）
```
