# kb-rust v2 需求文档

> 版本：v2.1.1
> 建立时间：2026-04-25
> 依据：TASK_REQUIREMENTS.md Skill 1 + 两篇微信参考文章（A1/A2）+ 原版 bash 实现

> **实现状态图例**：✅ 已实现　⚠️ 部分/stub　❌ 未实现

---

## 零、v2 总体完成度

```
需求完成：R1 ✅  R2 ⚠️  R3 ❌  R4 ⚠️  R5 ❌  R6 ❌  R7 ⚠️  R8 ✅  R9 ❌  R10 ❌
命令完成：16 命令中 12 ✅  1 ⚠️  3 ❌
frontmatter：6 字段已支持，待支持剧情分解字段
```

---



---

## 一、v1 现状总结

### v1 已实现（锁定，不动）

| 命令 | 状态 | 备注 |
|------|------|------|
| init | ✅ | 创建目录结构 + 空 .index.jsonl |
| add | ✅ | 生成 Markdown + 追加 .index.jsonl |
| list | ✅ | 按类型统计 |
| query | ✅ | 按类型查询 |
| search | ✅ | 名称/标签全文搜索（大小写不敏感） |
| rebuild | ✅ | 从 Markdown frontmatter 重建索引 |

### v1 frontmatter 解析规则

```markdown
---
name: xxx           ← 解析（优先）
created: xxx         ← 解析
tags: [a,b,c]        ← 解析 YAML 数组
tags: a,b,c          ← 解析逗号分隔
---

# 标题            ← 备选（无 frontmatter 时）
```

### v1 已知限制

- 全量文本扫描，>10000 条性能下降
- rebuild 依赖 Markdown 文件存在，文件丢失则索引不更新
- `entry_type` 由文件所在目录推断，无 frontmatter 字段

---

## 二、v2 功能需求（来源：原始参考文档）

### 需求 R1：工作流说明书中央大脑 ✅ 已实现

**来源**：A1/A2「工作流说明书.md」，AI 开工前必读

> "创建统一的工作流说明书作为项目中央大脑，AI 开工前必须先阅读该文件，说明书随项目更新自动更新。"

**实现**：
- `workflow` 命令输出 `WORKFLOW.md` 内容（存在则读，不存在则输出内置默认模板）
- 内置模板位于 `src/default_workflow.md`，含 Ingest/Query/Lint 三操作说明
- 格式：Markdown，含项目概述、目录结构、页面写作规范

**本项目应用**：
```
knowledge-base/
├── WORKFLOW.md               # ✅ 用户可自定义，workflow 命令优先读此文件
└── _compiled/
    └── _log.md              # ✅ 记录每次 workflow 更新
```

---

### 需求 R2：人物/角色形象管理 ⚠️ 部分实现

**来源**：A1/A2「人物形象文件夹」，锁定人物后 AI 创作前必须调用

> "要求单独创建人物形象文件夹，创作前必须调用指定形象。"

**实现**：
- ✅ `chars` 命令列出所有角色及状态（stable/wip/retired）
- ✅ frontmatter 支持 `status:` 字段（`add` 时自动写入 `stable`）
- ✅ `rebuild` 解析 `status:` 字段
- ❌ `_index.md` 角色总索引（含出场记录）— 待实现
- ❌ 角色参考图路径管理 — 待实现

**本项目应用**：
```
knowledge-base/characters/
├── protagonist.md    # ✅ status: stable
├── antagonist.md     # ✅ status: stable/wip
├── supporting-*.md    # ✅ status: wip/retired
└── _index.md        # ❌ 待实现
```

---

### 需求 R3：剧情分解标准化 ❌ 未实现

**来源**：A1/A2「剧情分解文件」，每章含页码/概述/出场人物/场景描述

> "要求AI提取每章内容创建剧情分解文件，包含页码、概述、出场人物，再生成含地点、对话、分镜的场景描述。"

**待实现**：
- `plot-template` 命令：输出剧情分解标准模板
- `plot/` 目录结构：`Chapter-01.md` 含 `original_pages/summary/characters/scenes` 字段
- frontmatter 支持上述字段解析

---

### 需求 R4：双链索引管理 ⚠️ 部分实现

**来源**：A1/A2「所有链接支持直接跳转」「双链联动」

> "所有文件设置双链，实现人物-剧情-场景联动。角色退场需同步更新人物索引。"

**实现**：
- ✅ `rebuild` 时用 regex 解析 `[[wikilinks]]`
- ✅ `_backlinks.json`：每条 `target → [source1, source2, ...]`
- ✅ `backlinks <target>` 命令：查询指向某条目的所有文件
- ❌ 删除角色时提示哪些文件引用了该角色 — 待实现

---

### 需求 R5：反馈优化记录 ❌ 未实现

**来源**：A1/A2「反馈优化」，第一回→第四回达标率 50%→70%

> "创建标准画风参考文件和作品风格指导全集，记录作者偏好的风格元素，用于指导后续创作。"

**待实现**：
- `styles/_accepted/` 目录：达标样例（含风格标签）
- `styles/_rejected/` 目录：废片记录（含失败原因）
- `yield-stats [--range YYYY-MM]` 命令：按环节/时间统计良品率趋势

---

### 需求 R6：Git 版本控制集成 ❌ 未实现

**来源**：A1/A2「Git 版本控制」，10分钟自动备份

> "AI批量处理文件的能力越强，你就越需要版本控制来兜底。"

**待实现**：
- `git-hint <file>`：提示文件是否已提交（仅提示，不执行）
- `git-hint`：提示有哪些新增文件未提交

---

### 需求 R7：Biji API 同步 ⚠️ stub

**来源**：TASK_REQUIREMENTS.md Skill 1「得到笔记 OpenAPI」

> "核心能力：得到笔记 OpenAPI [网络] + GitHub 双源"

**实现**：
- ✅ `sync-biji` 命令存在（stub）
- ✅ 需 `--features biji` 启用（默认不编译）
- ❌ 实际 API 调用 — 待实现

---

### 需求 R8：项目隔离 ✅ 已实现

**来源**：A1/A2「拷贝项目和Skills到其他设备即可直接开工」

> "换设备拷贝项目即可直接开工。"

**实现**：
- ✅ `init` 时自动创建 `.project.json`（项目名/创建时间/描述/版本）
- ✅ `project-info` 命令输出项目元数据
- ✅ 单知识库根目录 = 单项目，`--kb-dir` 隔离

---

### 需求 R9：Auto-commit 提示（不执行） ❌ 未实现

**来源**：A1/A2「将自动提交间隔设置为10分钟」

**待实现**：
- `backup-hint` 命令：提示距上次提交 >10 分钟且有新条目未提交

---

### 需求 R10：向量/Embedding 搜索（远期） ❌ 未实现

**来源**：SKILL.md 提到「自动化向量图」

> "Obsidian 双向链接格式支持" + "自动化向量图"

**待实现（v3）**：
- `search-v <query>`：基于标签相似度搜索（轻量，无需真实 embedding）

---

## 三、目录结构（v2 推荐）

```
knowledge-base/
├── .project.json          # 项目元数据（v2 新增）
├── .index.jsonl           # 单一索引
├── _backlinks.json        # 双向链接索引（v2 新增）
├── _workflow/              # 全局工作流说明书
│   └── workflow.md
├── characters/            # 角色设定
│   ├── _index.md          # 角色总索引
│   ├── protagonist.md
│   ├── antagonist.md
│   └── supporting-*.md
├── world/                 # 世界观
├── plot/                  # 剧情分解（标准化格式）
│   ├── _template.md
│   └── Chapter-*.md
├── styles/                # 风格参数
│   ├── _accepted/         # 达标样例
│   ├── _rejected/         # 废片记录
│   └── style-*.md
├── voices/                # 配音设定
├── experience/           # 经验知识
└── reference-articles/    # 参考原文 PDF（不建索引）
    ├── A1_*.pdf
    └── A2_*.pdf
```

---

## 四、v2 命令设计

| 命令 | 来源 | 实现 | 说明 |
|------|------|------|------|
| init | v1 | ✅ | 初始化目录结构（含 _compiled/ + .project.json） |
| add | v1 | ✅ | 添加条目（含 updated/status 字段） |
| list | v1 | ✅ | 列出所有 |
| query | v1 | ✅ | 按类型查询 |
| search | v1 | ✅ | 全文搜索 |
| rebuild | v1→v2 | ✅ | 重建索引 + 双链解析 + _index.md + _overview.md |
| `workflow` | R1 | ✅ | 输出 WORKFLOW.md |
| `chars` | R2 | ✅ | 列出角色及状态 |
| `plot-template` | R3 | ❌ | 输出剧情分解标准模板 |
| `backlinks <target>` | R4 | ✅ | 查找指向 target 的文件 |
| `yield-stats` | R5 | ❌ | 输出良品率趋势 |
| `git-hint <file>` | R6 | ❌ | 提示文件是否已提交 |
| `sync-biji` | R7 | ⚠️ | 同步 GetBiji API（stub，需 --features biji） |
| `project-info` | R8 | ✅ | 输出项目元数据 |
| `backup-hint` | R9 | ❌ | 提示备份时机 |
| `search-v <query>` | R10 | ❌ | 标签相似度搜索 |
| `errors` | R11 | ❌ | 列出所有 fail case 条目（C19） |

**汇总**：✅ 12 命令　⚠️ 1 命令（stub）　❌ 3 命令

---

## 五、v2 frontmatter 格式扩展

```markdown
---
name: 角色名
entry_type: characters
status: stable          # ✅ stable | wip | retired
created: 2026-04-25      # ✅
updated: 2026-04-25      # ✅ rebuild 时更新
tags: [protagonist, male, warrior]  # ✅
sources: [original.md]    # ✅ v2 支持，extract_sources() 解析
---

# 角色名

## 形象描述
...

## 出场记录
- 第1回：首次出场
- 第3回：再次出场
```

**已支持字段**（v2 实现）：
- `name:` — ✅ extract_title() 优先读
- `entry_type:` — ✅ infer_type() 由目录推断
- `created:` — ✅ extract_created()
- `updated:` — ✅ extract_updated()，add 时自动写入
- `status:` — ✅ extract_status()，add 时自动 = stable
- `tags:` — ✅ extract_tags()，YAML 数组和逗号分隔均支持
- `sources:` — ✅ extract_sources()，YAML 数组格式

**待支持字段**：
- `original_pages:` / `summary:` / `characters:` / `scenes:` — R3 剧情分解
- `backlinks:` — 由 rebuild 自动生成，不读入

---

## 六、数据流（v2）

```
[GetBiji API] ──sync-biji──→ knowledge-base/*.md ──rebuild──→ .index.jsonl
                                        ↑                        ↓
                               [手动添加/修改]               [search/query/chars/...]
                                        ↑                        ↓
                               [Git 本地备份] ←──backup-hint── [AI 操作提示]
                                        ↓
                             [GitHub 加密备份]（C11 backup.sh）

[新源文件] ──ingest──→ _compiled/_log.md（时序记录）
[新 Markdown] ──rebuild──→ .index.jsonl + _backlinks.json + _index.md + _overview.md
[WORKFLOW.md] ──workflow──→ 输出工作流说明书
```

**已实现链路**（✅）：
- `add` → MD 文件 + `.index.jsonl` + `_compiled/_log.md`
- `rebuild` → `.index.jsonl` + `_backlinks.json` + `_compiled/_index.md` + `_compiled/_overview.md`
- `workflow` → 输出 `WORKFLOW.md`（或内置默认）

**待实现链路**（R11）：
- 任何错误发生 → 自动追加 fail case 条目到 `.index.jsonl`（experience 类型，标签 fail-case,kb-error）
- `errors` 命令 → 列出所有 fail case（C19 自动记录）

---

## 七、参考来源索引

| 来源 | 需求 | 备注 |
|------|------|------|
| A1（2026-04-24，微信） | R1/R2/R3/R5/R6/R8 | 完整案例：小李飞刀漫画 |
| A2（2026-04-26，微信） | R1/R2/R3/R5/R6/R8 | 结构化摘要版 |
| TASK_REQUIREMENTS.md Skill 1 | R7 | Biji API |
| SKILL.md | R10 | 向量/Embedding（远期） |
| TASK_REQUIREMENTS.md C19 | R11 | 错误自动记录入知识库 |

---

## 十、需求 R11：错误自动记录（新增 2026-04-25）

**来源**：C19「发现违规 → 记录并修复」

> "发现违反 C0-C18 约束的事实，立即：① 记入 knowledge-base/.index.jsonl（fail case 条目）② 修复不合理之处。不问用户，直接执行。"

**态控设计**：

| 态 | 触发条件 | 行为 | 典型场景 |
|---|---------|------|---------|
| **调试态（默认开启）** | `KB_AUTO_LOG_ERRORS=1` 或 `--debug` 标志 | 错误 → 自动追加 fail case 条目 | 开发 kb-rust 本身、调试生产、调试优化 |
| **运行态（默认关闭）** | 环境变量未设且无 `--debug` | 不写 fail case，只输出到 stderr | 用户正常使用 |

**原因**：开发调试时需要积累错误经验（C17/C19），但运行态不应污染用户知识库。

**fail case 条目格式**：
```json
{
  "entry_type": "experience",
  "name": "FAIL: rebuild parse-error",
  "file": null,
  "tags": "fail-case,kb-error",
  "created": "2026-04-25T...",
  "error_cmd": "rebuild",
  "error_detail": "无法解析 frontmatter：karpathy_llm_wiki_original.md"
}
```

**自动记录的错误类型**：
- `rebuild` 时无法解析的 MD 文件
- `add` 时文件已存在的冲突
- `ingest` 时格式不支持
- `sync-biji` 时 API 调用失败
- 索引文件损坏（JSONL 解析失败）

**补充设计**：
- fail case 条目永久保留（供后续分析）
- `kb-rust errors` 命令：列出所有 fail case（按时间倒序，标签过滤 fail-case）
- `lint` 输出中增加 `Fail cases: N`
- 运行态强制关闭：`KB_AUTO_LOG_ERRORS=0`

---

## 八、v2 优先级

| 优先级 | 需求 | 原因 | 状态 |
|--------|------|------|------|
| P0 | R1 工作流说明书 | 中央大脑，所有 AI 开工前必读 | ✅ |
| P0 | R8 项目元数据 | 多项目隔离基础 | ✅ |
| P1 | R2 角色状态管理 | 直接影响 S2 风格锚定 | ⚠️ 部分 |
| P1 | R4 双链索引 | 实现"人物-剧情-场景联动" | ⚠️ 部分 |
| P1 | R7 Biji API | Skill 1 核心能力，Get笔记连接目的 | ⚠️ stub |
| P2 | R3 剧情分解模板 | S3 分镜输入标准化 | ❌ |
| P2 | R5 反馈记录 | S5 良品率追踪基础 | ❌ |
| P3 | R6 Git 辅助 | C11 已实现，可延后 | ❌ |
| P3 | R9 Auto-commit 提示 | 辅助 R6 | ❌ |
| P4 | R10 向量搜索 | v3 考虑，当前可先用标签模拟 | ❌ |
| P1 | R11 错误自动记录 | C19 约束，知识库错误自动记入索引（C17 查询来源） | ❌ |
| P0 | R12 项目目录约束 | C-DEV：测试目录标注与生产 KB 边界 | ✅ v2.1.1 已实现 |

---

## 十一、需求 R12：项目目录约束（v2.1.1 新增）

**来源**：监工判断（测试目录不得污染生产知识库）

> 测试目录必须明确标注「开发测试数据」，与生产知识库 `knowledge-base/` 严格隔离。

**约束内容（C-DEV）**：

| 目录 | 用途 | KB 管理 | 状态 |
|------|------|---------|------|
| `knowledge-base/` | **生产知识库** | ✅ 唯一数据源 | 活跃 |
| `kb-rust/knowledge-base-test/` | v1 开发烟测沙箱 | ❌ 禁止并入生产 KB | **标注为开发数据** |
| `kb-rust/v2/kb-v2-test/` | v2 开发烟测沙箱 | ❌ 禁止并入生产 KB | **标注为开发数据** |

**禁止行为**：
- 不得将测试 KB 条目合并入生产 KB（`knowledge-base/`）
- 不得删除测试目录作为"清理孤立页"手段
- 不得将测试数据放入 `knowledge-base/` 目录

**归档原则**：
- 归档文件存 `~/.backup/audio-comic-skills/kb-rust/`
- 项目目录仅保留当前版本（`kb-rust/v2/`）

| # | 痛点 | 现象 | 当前解法 | 未来方向 |
|---|------|------|---------|---------|
| T1 | PDF 无法直接检索 | PDF 必须手动提取为 .txt 才能搜索 | pdfplumber 提取全文 → .txt | v2 应支持直接解析 PDF/Word/EPUB 等通用文档格式 |
| T2 | 多源格式不统一 | 原著可能为 PDF/MOBI/TXT/EPUB | 手动转换 | 统一预处理管道 |

> T1 已实践：PDF → pdfplumber → .txt，chars: A1=6193, A2=2716
