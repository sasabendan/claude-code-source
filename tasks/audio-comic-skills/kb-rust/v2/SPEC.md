# kb-rust v2 规格说明书

> 版本：v2.1.1
> 更新：2026-04-26（v2.1.1 基建稳定化）
> 依据：Karpathy LLM Wiki 方法论 + nashsu + lucasastorian + A1/A2（小李飞刀案例）
> 核心原则：增量编译 ≠ RAG，Wiki 是持久复合产物，AI 维护，人类策展

---

## 一、设计理念（来自 Karpathy）

```
RAG（传统）：上传文件 → 检索相关片段 → LLM 每次从头推导
           无积累，问复杂问题必须重新拼凑
           知识每次重新发现，不积累

LLM Wiki（我们的）：上传文件 → LLM 增量构建 Wiki
                   Wiki 是持久复合产物
                   跨文档综合、交叉引用、矛盾标记
                   知识编译一次，持续更新
                   每次问答都在已有合成知识上工作
```

**三个核心操作**：

| 操作 | 定义 | v2 实现 |
|------|------|--------|
| **Ingest** | LLM 读源文件 → 更新/创建多个 Wiki 页面 → 更新 index/log | `kb-rust ingest <source>` |
| **Query** | 先读 index 找相关页面 → 读页面综合回答 → 有价值的答案归档为新页面 | `kb-rust query <question>` |
| **Lint** | 健康检查：矛盾/孤立页面/缺失交叉引用/过时声明 | `kb-rust lint` |

---

## 二、三层架构

```
┌─────────────────────────────────────────────────────┐
│  Layer 1: Raw Sources（不可变，source of truth）      │
│  knowledge-base/                                     │
│  ├── characters/    角色 MD 文件（原始设定）           │
│  ├── world/         世界观 MD 文件                   │
│  ├── plot/          剧情分解 MD 文件                 │
│  ├── styles/        风格参数 MD 文件                 │
│  ├── voices/        配音设定 MD 文件                  │
│  └── experience/    经验知识 MD 文件                  │
│       └─ 原始 PDF/TXT 等来源文件（如有）              │
├─────────────────────────────────────────────────────┤
│  Layer 2: Wiki（LLM 生成和维护，我们只读/策展）        │
│  knowledge-base/_compiled/                           │
│  ├── _index.md       内容目录（每条含链接+摘要+元数据） │
│  ├── _log.md         时序记录（ingest/query/lint 条目）│
│  ├── _overview.md    全局概要（源数/页数/关键发现）    │
│  ├── entities/       人物/组织/产品（从 characters/ 汇总）│
│  ├── concepts/       理论/方法/主题（从 experience/ 汇总）│
│  └── synthesis/      跨资料综合分析                   │
├─────────────────────────────────────────────────────┤
│  Layer 3: Schema（工作规范，告诉 AI 如何运作）         │
│  knowledge-base/                                     │
│  ├── WORKFLOW.md    工作流说明书（AI 开工前必读）      │
│  └── 各个 Skill SKILL.md（已有的）                   │
└─────────────────────────────────────────────────────┘
```

**关键：Layer 1 和 Layer 2 分离。**
- Layer 1 是原始文件，AI 只读不写
- Layer 2 是 AI 生成的综合页面，AI 维护
- 人类策展 Layer 2，不直接编辑 Layer 1

---

## 三、目录结构（v2 最终）

```
knowledge-base/                    # 项目根目录（单项目隔离）
├── .project.json                  # 项目元数据（name/created/desc）  ← v2 新增
├── .index.jsonl                   # 单一索引（v1 兼容）
├── _backlinks.json                # 双向链接索引（v2 新增）          ← R4
├── _compiled/                     # AI 生成 Wiki（Layer 2）
│   ├── _index.md                  # 内容目录（v2 新增）
│   ├── _log.md                    # 时序记录（v2 新增）
│   ├── _overview.md               # 全局概要（v2 新增）
│   ├── entities/                  # 实体汇总
│   ├── concepts/                  # 概念汇总
│   └── synthesis/                 # 跨资料综合
├── characters/                    # Layer 1：角色（原始设定）
│   ├── _index.md                  # 角色总索引（含出场记录）
│   └── *.md                       # 各角色文件
├── world/                         # Layer 1：世界观
├── plot/                          # Layer 1：剧情分解（标准化格式）
│   ├── _template.md               # 剧情分解标准模板                ← R3
│   └── Chapter-*.md              # 各章剧情分解
├── styles/                        # Layer 1：风格参数
│   ├── _accepted/                 # 达标样例（v2 新增）              ← R5
│   ├── _rejected/                 # 废片记录（v2 新增）              ← R5
│   └── *.md
├── voices/                        # Layer 1：配音设定
├── experience/                    # Layer 1：经验知识
│   └── *.md
├── _workflow/                      # Schema 层：工作流说明书          ← R1
│   └── WORKFLOW.md               # AI 开工前必读
└── reference-articles/            # 参考原文（不建索引）
    └── *.pdf / *.txt
```

---

## 四、命令设计（v2）

### v1 命令（保持兼容）

| 命令 | 说明 |
|------|------|
| `init` | 初始化目录结构（含 .project.json + _compiled/） |
| `add` | 添加单条 |
| `list` | 列出所有 |
| `query` | 按类型查询 |
| `search` | 全文搜索 |
| `rebuild` | 重建索引（含双链解析 + _compiled 更新） |

### v2 新增命令

| 命令 | 优先级 | 说明 |
|------|--------|------|
| `workflow` | P0 | 输出当前项目工作流说明书 |
| `ingest <file>` | P1 | 摄入源文件 → 更新/创建多个 Wiki 页面 → 更新 _log.md |
| `q <question>` | P1 | 查询 Wiki（先读 _index.md → 读相关页面 → 综合回答 → 有价值答案归档） |
| `lint` | P2 | 健康检查（矛盾/孤立页面/缺失交叉引用/过时声明） |
| `chars [--status stable\|wip\|retired]` | P1 | 列出所有角色及状态 |
| `plot-template` | P2 | 输出剧情分解标准模板 |
| `backlinks <target>` | P1 | 列出指向 target 的所有文件 |
| `yield-stats [--range YYYY-MM]` | P2 | 输出良品率趋势（来自 _rejected/） |
| `git-hint [--file <path>]` | P3 | 提示文件是否已提交 |
| `project-info` | P0 | 输出项目元数据 |
| `sync-biji` | P1 | 同步 GetBiji API（环境变量 BIJI_API_KEY） |
| `backup-hint` | P3 | 提示备份时机（距上次提交 >10min 有未提交新条目） |

---

## 五、数据流（v2）

```
[新源文件] → ingest
     ↓
[LLM 分析：提取实体/概念/矛盾/结构建议]
     ↓
[更新/创建 Layer 2 Wiki 页面]
     ↓
[更新 _log.md（ingest 条目）]
     ↓
[更新 _index.md（内容目录）]
     ↓
[更新 _overview.md（全局概要）]
     ↓
[更新 _backlinks.json（双链索引）]

[用户提问] → q
     ↓
[读 _index.md 找相关页面]
     ↓
[读相关 Wiki 页面]
     ↓
[综合回答，有价值的归档为新 Wiki 页面]
     ↓
[更新 _log.md（query 条目）]
```

---

## 六、_log.md 格式（Karpathy 设计）

```markdown
## [2026-04-25] ingest | 角色：主角.md
- 创建实体页面：protagonist.md（entities/protagonist.md）
- 更新概念页面：audio-comic-workflow.md（concepts/audio-comic-workflow.md）
- 更新 _overview.md
- 来源：characters/protagonist.md
- 关键发现：主角具有"侠义精神"属性，影响其决策逻辑

## [2026-04-25] query | 李寻欢的决策逻辑是什么？
- 参考页面：entities/protagonist.md, concepts/audio-comic-workflow.md
- 回答：李寻欢的决策逻辑以"侠义优先"为原则，详见...
- 归档为：synthesis/li-xunhuan-analysis.md

## [2026-04-25] lint | 健康检查
- 发现孤立页面：experience/xxx.md（无任何页面引用）
- 矛盾：plot/Chapter-01.md 与 plot/Chapter-03.md 对同一事件描述不一致
- 建议深度研究：主角与反派的关系演变
```

格式规则：`## [YYYY-MM-DD] <type> | <description>`
- grep `"^## \[" _log.md | tail -5` 可解析最后 5 条

---

## 七、_index.md 格式（Karpathy 设计）

```markdown
# 知识库索引

最后更新：2026-04-25
总条目：25 | 源文件：18 | Wiki 页面：12

## 实体（Entities）
- [主角.md](entities/protagonist.md) — 李寻欢，侠义精神，决策优先原则 | 更新：2026-04-25
- [反派.md](entities/antagonist.md) — 上官金虹，野心勃勃 | 更新：2026-04-25

## 概念（Concepts）
- [有声漫画七环节流水线.md](concepts/audio-comic-workflow.md) — 脚本→分镜→生图→配音→合成→排版→发布 | 更新：2026-04-24
- [良品率追踪.md](concepts/yield-tracking.md) — 第一回 50%→第四回 70% | 更新：2026-04-24

## 源文件（Sources）
- [主角.md](characters/protagonist.md) — 角色设定，原著页码：12-15 | 更新：2026-04-25
- [Chapter-01.md](plot/Chapter-01.md) — 第一回：页码1-8，场景：梅庄 | 更新：2026-04-24

## 最近更新
- [2026-04-25] protagonist.md — 新增"侠义精神"属性
- [2026-04-25] audio-comic-workflow.md — 更新流水线描述
```

---

## 八、frontmatter 格式扩展（v2）

```markdown
---
name: 角色名称
entry_type: characters
status: stable              # R2：stable | wip | retired
created: 2026-04-25
updated: 2026-04-25         # v2 新增：最后更新时间
tags: [protagonist, male, warrior]
sources:                   # v2 新增：来源文件（用于溯源）
  - original-notes.md
  - plot/Chapter-01.md
backlinks:                 # v2：由 rebuild 时自动生成
  - plot/Chapter-01.md
  - characters/antagonist.md
---

# 角色名称

## 形象描述
...

## 出场记录
- 第1回：首次出场（梅庄）
- 第3回：再次出场（决战）
```

---

## 九、v2 优先级与依赖

```
P0（基础设施，必须先做）：
  ├── R8: 项目元数据（.project.json + project-info）
  ├── R1: 工作流说明书（WORKFLOW.md + workflow 命令）

P1（核心链路，依赖 P0）：
  ├── R4: 双链索引（_backlinks.json + backlinks 命令）
  ├── R2: 角色状态管理（status 字段 + chars 命令）
  ├── R7: Biji API（sync-biji 命令）
  └── → ingest / q / lint 依赖 R4 + R2

P2（增强功能）：
  ├── R3: 剧情分解模板（_template.md + plot-template 命令）
  └── R5: 反馈记录（_accepted/ + _rejected/ + yield-stats 命令）

P3（辅助功能，依赖 P0）：
  ├── R6: Git 辅助（git-hint 命令）
  └── R9: Auto-commit 提示（backup-hint 命令）

P4（远期，依赖 P3）：
  └── R10: 向量搜索（search-v 命令，基于标签相似度）
```

---

## 十、技术决策

| 决策 | 选择 | 原因 |
|------|------|------|
| Layer 2 生成方式 | AI（外部 LLM）调用 kb-rust 辅助工具处理 | kb-rust 是工具，不是 LLM |
| 文本搜索 vs 向量 | 分词搜索 + 图谱扩展（R4 backlinks） | 100-10000 条无明显性能问题 |
| 多格式支持 | 当前仅 MD，后续扩展 | 专注核心，参考 lucasastorian 架构 |
| Biji API | 环境变量 BIJI_API_KEY，失败不阻塞 | kb_sync_biji() 历史为空 stub |
| 增量 vs 全量 | rebuild = 全量扫描，ingest = 增量处理 | 保证一致性 |

---

## 十一、与 v1 的差异

| 维度 | v1 | v2 |
|------|----|----|
| 架构 | Markdown + JSONL 索引 | 三层架构（Raw/Wiki/Schema） |
| 索引 | .index.jsonl 单一索引 | .index.jsonl + _compiled/_index.md + _compiled/_log.md |
| 双链 | 不解析 | 解析 [[wikilinks]]，生成 _backlinks.json |
| Ingest | 无（add 单条） | 完整 ingest，生成多个 Wiki 页面 |
| Query | 文本搜索 | 先读 index → 读页面 → 综合（标准流程） |
| Lint | 无 | 定期健康检查 |
| 角色状态 | 无 | stable/wip/retired |
| 良品率 | 无 | _accepted/ + _rejected/ 追踪 |
| Biji | 空 stub | 完整实现 |
| 项目元数据 | 无 | .project.json |

---

## 十二、参考来源

| 来源 | 关键影响 |
|------|---------|
| Karpathy llm-wiki（原始方法论，桌面文件 `llmwiki.md` 为 canonical 原版） | 三层架构 / Ingest-Query-Lint / index.md + log.md |
| nashsu/llm_wiki | purpose.md（WORKFLOW.md 对应）/ 两步思维链 / 增量缓存 |
| lucasastorian/llmwiki | MCP 工具设计 / 写作规范（视觉元素+引用） |
| A1/A2（微信参考文章） | 小李飞刀案例 / 中央大脑 / 反馈优化循环 / 版本控制 |
| TASK_REQUIREMENTS.md | Skill 1 要求：GetBiji API + 增量式 Wiki + Obsidian |
| TASK_REQUIREMENTS.md C19 | R11：错误自动记录入知识库（fail case） |

---

## 十三、v2 实现状态（2026-04-25）

### 已实现

| 命令 | 优先级 | 状态 | 说明 |
|------|--------|------|------|
| init | v1 | ✅ | 幂等非破坏：缺 .project.json/_log.md 头时补入，不覆盖已有内容 |
| add | v1 | ✅ | 生成 MD + 追加 .index.jsonl |
| list | v1 | ✅ | 按类型统计 |
| query | v1 | ✅ | 按类型查询 |
| search | v1 | ✅ | 全文搜索 |
| rebuild | v1→v2 | ✅ | 重建索引 + 双链解析 + _index.md + _overview.md |
| workflow | P0 | ✅ | 输出 WORKFLOW.md（默认或自定义） |
| project-info | P0 | ✅ | 输出 .project.json |
| chars | P1 | ✅ | 列出角色及状态 |
| backlinks | P1 | ✅ | 查找指向 target 的文件 |
| lint | P2 | ✅ | 健康检查（孤立页面/bad entries/总条目/双链统计） |
| ingest | P1 | ✅ | 摄入源文件 → 更新 _log.md（当前仅 .md，详见限制说明） |
| sync-biji | P1 | ⚠️ | stub（需 --features biji） |

### v2 新增数据结构

```
knowledge-base/
├── .project.json           # 项目元数据（v2 新增）
├── .index.jsonl            # 扩展：新增 updated/status/sources/backlinks 字段
├── _backlinks.json        # 双向链接索引（v2 新增）
└── _compiled/
    ├── _index.md           # 内容目录（Karpathy 设计，v2 实现）
    ├── _log.md            # 时序记录（Karpathy 设计，v2 实现）
    ├── _overview.md        # 全局概要（v2 实现）
    ├── entities/          # 实体汇总目录
    ├── concepts/           # 概念汇总目录
    └── synthesis/          # 跨资料综合目录
```

### KbEntry v2 字段扩展

```json
{
  "entry_type": "characters",
  "name": "李寻欢",
  "file": "characters/protagonist.md",
  "tags": "protagonist,male",
  "created": "2026-04-25T00:00:00Z",
  "updated": "2026-04-25T12:00:00Z",    // v2 新增
  "status": "stable",                   // v2：stable|wip|retired
  "sources": ["original-notes.md"],     // v2 新增
  "backlinks": ["plot/Chapter-01.md"]   // v2：由 rebuild 时自动填充
}
```

### 技术决策

| 决策 | 选择 | 原因 |
|------|------|------|
| Layer 2 生成方式 | 外部 LLM 调用 kb-rust 处理索引/日志 | kb-rust 是工具，不是 LLM |
| 双链解析 | rebuild 时用 regex 解析 `[[...]]` | 轻量，无需外部依赖 |
| backlinks 存储 | 独立 `_backlinks.json`，不混入 .index.jsonl | 解耦，支持大型知识库 |
| index.md 更新 | rebuild 时自动更新 | 保证一致性 |
| 日志格式 | `## [YYYY-MM-DD HH:MM:SS] <type> | <desc>` | 可用 grep 解析（Karpathy 原设计） |

### 下一步（未完成）

| 优先级 | 项目 | 说明 |
|--------|------|------|
| P0 | WORKFLOW.md 生成 | init 时自动创建默认 WORKFLOW.md |
| P1 | R11 错误自动记录 | 任何 kb-rust 错误 → fail case 条目追加到 .index.jsonl |
| P1 | Biji API 实现 | sync-biji 完整实现（需 --features biji） |
| P1 | Layer 2 Wiki 生成 | ingest → AI 分析 → `_compiled/` 更新 |
| P2 | plot-template 命令 | 输出剧情分解标准模板 |
| P2 | yield-stats 命令 | 良品率统计（来自 _accepted/ + _rejected/） |
| P3 | git-hint 命令 | 提示文件未提交（Git 辅助） |
| P4 | search-v 命令 | 标签相似度搜索 |

---

## 十四、已知限制

| # | 限制 | 说明 | 解决方案 |
|---|------|------|---------|
| L1 | ingest 仅支持 .md | 当前版本仅能摄入 Markdown 文件 | 未来支持 .txt/.pdf/.epub/.docx（T1/R3 方向） |
| L2 | rebuild 对非标准 MD | HTML 残留/无 frontmatter/无 # 标题的文件 | ✅ 已修复：自动回退到文件名作为 name |
| L3 | search 全量文本扫描 | >10000 条性能下降 | 未来可考虑 R10 向量搜索 |
| L4 | rebuild 依赖文件存在 | 文件删除后索引不自动更新 | 手动 rebuild 或 lint 发现孤立条目 |
| L5 | 项目目录内测试 KB | `knowledge-base-test/` 和 `v2/kb-v2-test/` 为开发沙箱，不在生产 KB 管理范围内 | **禁止删除或合并** — 仅作开发烟测用，生产知识库为 `knowledge-base/` |

---

## 十五、项目目录约束

> **约束 C-DEV**：项目目录结构规范，防止测试数据污染生产知识库

### 目录分类

| 目录 | 用途 | KB 管理 | 约束 |
|------|------|---------|------|
| `kb-rust/v2/` | 当前版本源码/配置/二进制 | ✅ 是（工作区） | 活跃开发区 |
| `knowledge-base/` | **生产知识库** | ✅ 是（索引） | **唯一生产数据源**，不许放测试数据 |
| `knowledge-base-test/` | v1 开发烟测沙箱 | ❌ 否 | 仅开发烟测用，禁止并入生产 KB |
| `v2/kb-v2-test/` | v2 开发烟测沙箱 | ❌ 否 | 仅开发烟测用，禁止并入生产 KB |

### 约束规则

1. **生产知识库边界**：`knowledge-base/` 是唯一生产 KB，所有 Skills 文档和经验条目必须进入该目录
2. **测试数据隔离**：测试目录内的 `.index.jsonl` 和 `_compiled/` 不参与生产索引
3. **rebuild 扫描范围**：仅扫描 `knowledge-base/`（`--kb-dir` 指定），不扫描 `knowledge-base-test/` 或 `kb-v2-test/`
4. **禁止合并**：不得将测试 KB 条目合并入生产 KB，不得删除测试目录作为"清理孤立页"的手段
