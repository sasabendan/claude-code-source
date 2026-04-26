# kb-rust v2 开发日志

---

## [v2.1.1] - 2026-04-26

### 基建稳定化：入口不漂移

**来源**：监工判断（当前优先级高于功能扩展）

#### add 后 auto-rebuild
- 修复：`add` 执行完自动触发 `rebuild_index_v2()`
- 效果：`.index.jsonl` 和 `_compiled/_index.md` 永远同步，不再出现"索引 38 条但入口目录 37 条"的情况
- 影响：`add` 耗时略增（多一次全量扫描），但当前规模（<100 条）可接受

#### ingest 后 auto-rebuild
- 修复：`ingest` 执行完自动触发 `rebuild_index_v2()`
- 效果：摄入新源文件后立即更新入口索引和双链

#### init 非破坏性补全
- 修复：`init_v2()` 改为纯幂等操作，`ensure_project()` 不覆盖已有文件
- 效果：对已有库运行 `init` 不会破坏内容，只补全缺失的 `.project.json` / `_compiled/_log.md` 头
- 新增：`init` 执行后写 `_compiled/_log.md` 日志条目

#### WORKFLOW.md 创建
- 新增：`knowledge-base/WORKFLOW.md`（双链标准 + 入口索引 + 三层架构 + 同步保证）
- 双链最低标准：角色≥3 个 `[[...]]`，剧情/概念≥2 个，参考文章≥1 个
- 目标：逐步补链接后 Obsidian 图谱视图可见知识网络

### 测试结果
```
✅ init 对已有库补全 .project.json（不破坏现有内容）
✅ add 触发 auto-rebuild → .index.jsonl 和 _index.md 总条目同步（38 条）
✅ ingest 触发 auto-rebuild
✅ workflow 输出自定义 WORKFLOW.md（而非内置模板）
✅ rebuild 后 WORKFLOW.md 排除在外（不进入索引）
```

### 项目目录整理（v2.1.1）

#### 测试目录标注（C-DEV）
- **新增**：`SPEC.md` 第十五章「项目目录约束」，明确测试目录定位
- **标注**：`knowledge-base-test/` 和 `v2/kb-v2-test/` 标注为「开发测试数据」，禁止并入生产 KB
- **约束**：生产知识库边界仅 `knowledge-base/`，不得删除测试目录作为"清理孤立页"手段
- **变更**：归档迁移机制（archive/ → `~/.backup/`），项目目录仅保留当前版本

---

## [v2.1.0] - 2026-04-25

### 新增需求：R11 错误自动记录

**来源**：TASK_REQUIREMENTS.md C19「发现违规 → 记录并修复」

> "发现违反 C0-C18 约束的事实，立即：① 记入 knowledge-base/.index.jsonl（fail case 条目）② 修复不合理之处。不问用户，直接执行。"

**态控设计**：

| 态 | 触发条件 | 行为 | 典型场景 |
|---|---------|------|---------|
| **调试态（默认开启）** | `KB_AUTO_LOG_ERRORS=1` 或 `--debug` | 错误 → 自动追加 fail case 条目到 .index.jsonl | 开发 kb-rust 本身、调试生产、调试优化 |
| **运行态（默认关闭）** | 环境变量未设且无 `--debug` | 不写 fail case，只输出到 stderr | 用户正常使用 |

**fail case 条目格式**：
```json
{
  "entry_type": "experience",
  "name": "FAIL: rebuild parse-error",
  "tags": "fail-case,kb-error",
  "created": "2026-04-25T...",
  "error_cmd": "rebuild",
  "error_detail": "无法解析 frontmatter：xxx.md"
}
```

**待实现**：
- `errors` 命令：列出所有 fail case（按时间倒序，标签过滤 fail-case）
- `lint` 输出增加 `Fail cases: N`
- 各命令中的错误捕获点接入自动记录

### 文档更新

- `REQUIREMENTS_V2.md` 新增 R11 需求文档（含态控设计）
- `SPEC.md` 新增「已知限制」章节（L1-L4）
- 所有命令实现状态在两文档中保持一致

---

## [v2.0.1] - 2026-04-25

### Bug Fixes

- **rebuild: 空 name 回退到文件名**
  - 问题：部分 MD 文件无 frontmatter 也无 `# 标题`（如 HTML 残留的 `karpathy_llm_wiki_original.md`），导致索引产生 name="" 的脏条目，污染 .index.jsonl 和 _compiled/_index.md
  - 修复：extract_title() 返回空时，自动使用文件名（去掉 .md 后缀）作为 name
  - 影响：query/search 输出不再出现空标题条目；_compiled/_index.md 入口目录条目可读

- **ingest: 错误信息补充说明**
  - 问题：仅 .md 时报错 "Only .md files supported" 不够明确
  - 修复：报错信息增加 "Future versions may support: .txt, .pdf, .epub, .docx"

- **lint: 增加 bad entries 计数**
  - 修复：lint 输出中增加 "BAD entries (empty name)" 统计
  - 目的：让用户清楚知道索引中有多少不可解析条目，rebuild 后会消除

### 测试（2026-04-25，用户测试反馈）

```
✅ rebuild：karpathy_llm_wiki_original.md → name="karpathy_llm_wiki_original"（文件名回退）
✅ query experience：首行不再是 | 空记录
✅ ingest .txt：报错信息清晰，预告未来支持格式
✅ lint：bad_entries=0（回退策略生效）
```

---

## [v2.0.0] - 2026-04-25

### 背景

v2 开发基于以下原始参考文档：

1. **Karpathy llm-wiki.md**（原始方法论，桌面文件 `llmwiki.md` 为 canonical 版本）
   - 三层架构：Raw Sources / Wiki / Schema
   - 三个核心操作：Ingest / Query / Lint
   - index.md（内容目录）+ log.md（时序记录）
   - Obsidian 兼容，`[[wikilinks]]` 双链

2. **微信参考文章 A1/A2**（2026-04-24/26）
   - 小李飞刀漫画案例：起点=原著 PDF，AI 理解创作标准
   - 工作流说明书.md（中央大脑）
   - 反馈优化循环：第一回 50% → 第四回 70%

3. **nashsu/llm_wiki**（桌面应用）
   - purpose.md（目标定义，对应 WORKFLOW.md）
   - 两步思维链摄入

4. **lucasastorian/llmwiki**（Web+MCP）
   - MCP 工具设计规范

### 架构变更

**v1（三层混沌）**：
```
knowledge-base/
├── .index.jsonl    ← 单一索引
├── characters/
├── world/
└── ...
```

**v2（Karpathy 三层）**：
```
knowledge-base/
├── .project.json              ← P0 新增：项目元数据
├── .index.jsonl              ← 扩展字段（updated/status/sources/backlinks）
├── _backlinks.json           ← P1 新增：双向链接索引
├── WORKFLOW.md               ← P0 新增：Schema 层，AI 开工前必读
├── _compiled/                ← P1 新增：Layer 2，AI 生成 Wiki
│   ├── _index.md             ← Karpathy 设计：内容目录
│   ├── _log.md               ← Karpathy 设计：时序记录
│   ├── _overview.md          ← 新增：全局概要
│   ├── entities/             ← 实体汇总
│   ├── concepts/             ← 概念汇总
│   └── synthesis/             ← 跨资料综合
├── characters/               ← Layer 1：原始文件（不可变，AI 只读）
├── world/
├── plot/
├── styles/
├── voices/
└── experience/
```

### 数据结构变更

**KbEntry v2 新增字段**：
```json
{
  "entry_type": "characters",
  "name": "李寻欢",
  "file": "characters/protagonist.md",
  "tags": "protagonist,male",
  "created": "2026-04-25T00:00:00Z",
  "updated": "2026-04-25T12:00:00Z",    // v2 新增
  "status": "stable",                   // v2 新增：stable|wip|retired
  "sources": ["original-notes.md"],       // v2 新增
  "backlinks": ["plot/Chapter-01.md"]   // v2：rebuild 时自动填充
}
```

### 新增命令

| 命令 | 优先级 | 说明 |
|------|--------|------|
| `workflow` | P0 | 输出当前项目工作流说明书（默认或自定义） |
| `project-info` | P0 | 输出项目元数据（.project.json） |
| `chars` | P1 | 列出所有角色及状态（stable/wip/retired） |
| `backlinks <target>` | P1 | 查找指向 target 的所有文件 |
| `ingest <file>` | P1 | 摄入源文件 → 更新 _log.md |
| `lint` | P2 | 健康检查（孤立页面/总条目/双链统计） |
| `sync-biji` | P1 | 同步 GetBiji API（stub，需 --features biji） |

### rebuild v2 扩展

v1 rebuild → 扫描 MD + 写 .index.jsonl

v2 rebuild → 扫描 MD + 写 .index.jsonl **+ 解析 [[wikilinks]] + 写 _backlinks.json + 更新 _index.md + 更新 _overview.md**

### 依赖变更

| 依赖 | v1 | v2 | 原因 |
|------|-----|-----|------|
| walkdir | ✅ | ✅ | 目录遍历 |
| chrono | ✅ | ✅ | 时间戳 |
| serde_json | ✅ | ✅ | JSON 处理 |
| serde_yaml | ✅ | ✅ | YAML frontmatter |
| rusqlite | ❌ | ❌ | v1 已移除，v2 不引入 |
| regex | ❌ | ✅ | v2 新增：双链 `[[wikilinks]]` 解析 |
| reqwest/tokio | ❌ | ⚠️ | v2 可选：biji feature（默认不启用） |

### 测试结果（烟测 2026-04-25）

```
✅ 编译通过：667 行 Rust，release 8.8s
✅ init：新建 _compiled/ + .project.json + 6 个 Layer 1 目录
✅ add：生成 MD + 追加索引 + 写 _log.md
✅ workflow：输出默认工作流说明书（中文，Karpathy 方法论）
✅ chars：列出角色及状态
✅ rebuild：26 条（含双链解析）
✅ lint：健康检查（孤立页面 25 / 总条 26 / 双链 0）
✅ ingest：摄入源文件 → 写 _log.md
✅ project-info：输出 .project.json
✅ v1 兼容：list / search / query 全部正常
```

**注**：现有知识库无双链文件（无 `[[wikilinks]]` 语法），lint 显示 25 个孤立页面属正常行为。

---

## [v1.0.0] - 2026-04-24

### 背景

v1 是从 SQLite 版本重建而来。原始需求：C1（Rust 重写）+ LLM Wiki 架构 + JSONL 索引 + Markdown 文件管理。

### 架构

```
knowledge-base/
├── .index.jsonl    ← 单一 JSONL 索引
├── characters/
├── world/
├── plot/
├── styles/
├── voices/
└── experience/
```

### 命令

| 命令 | 说明 |
|------|------|
| init | 初始化目录结构 |
| add | 添加条目（生成 MD + 追加索引） |
| list | 按类型统计 |
| query | 按类型查询 |
| search | 全文搜索（大小写不敏感） |
| rebuild | 从 Markdown frontmatter 重建索引 |

### frontmatter 解析

```markdown
---
name: xxx           ← 解析（优先）
created: xxx         ← 解析
tags: [a,b,c]        ← 解析 YAML 数组
tags: a,b,c          ← 解析逗号分隔
---

# 标题            ← 备选（无 frontmatter 时）
```

### 已知问题

- JSONL 字段名曾为 `type`，后统一为 `entry_type`（Python 批量替换 36 条）
- rusqlite 依赖引入后被移除（LLM Wiki 不需要数据库文件）

### 测试结果（v1 烟测 2026-04-24）

```
✅ init：创建 6 目录 + 空 .index.jsonl
✅ add：生成 MD + 写 .index.jsonl
✅ list：Total: 24 entries
✅ rebuild：Rebuilt: 24 entries
✅ search supervisor：3 results
```
