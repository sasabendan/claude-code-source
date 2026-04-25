# kb-rust: LLM Wiki Knowledge Base Manager

## 定位

Rust 重写的知识库管理工具（C1 要求）。管理 LLM Wiki 的 Markdown 文件 + 单一 JSONL 索引入口，零数据库文件。

## 数据架构

```
knowledge-base/
├── .index.jsonl          # 单一索引入口（JSONL，每行一条）
├── experience/           # 经验知识
├── styles/               # 风格参数（映射为 style）
├── plot/                 # 剧情结构
├── characters/           # 角色设定
├── world/                # 世界观
└── voices/               # 配音设定
```

## Markdown 格式（Frontmatter）

每个 Markdown 文件使用 YAML frontmatter：

```markdown
---
type: experience
name: 知识名称
created: 2026-04-25T00:00:00Z
tags: [tag1, tag2, tag3]
---

## 正文标题

内容...
```

关键字段：
- `name`：知识条目名称（用于搜索和显示）
- `type`：分类（frontmatter 中的字段名，rebuild 时转为 `entry_type`）
- `tags`：标签数组
- `created`：ISO 8601 时间戳

## .index.jsonl 格式

rebuild 从 Markdown frontmatter 提取信息，写入 JSONL：

```json
{"entry_type":"experience","name":"知识名称","file":"experience/xxx.md","tags":"tag1,tag2","created":"2026-04-25T00:00:00Z"}
```

字段名：`entry_type` / `name` / `file` / `tags` / `created`

- `entry_type` = frontmatter 的 `type` 字段（experience/styles/plot/...）
- `file` = 相对于 knowledge-base/ 的路径
- `tags` = 逗号分隔字符串

## 编译

```bash
cd kb-rust
cargo build --release
./target/release/kb-rust --help
```

## 命令

```bash
# 初始化目录结构（创建 experience/styles/plot... + 空 .index.jsonl）
kb-rust --kb-dir knowledge-base init

# 列出所有条目（按类型统计）
kb-rust --kb-dir <path> list

# 按类型查询
kb-rust --kb-dir <path> query experience

# 搜索名称/标签（全文大小写不敏感）
kb-rust --kb-dir <path> search supervisor

# 从 Markdown 文件重建索引
kb-rust --kb-dir <path> rebuild

# 追加索引条目（自动创建 Markdown 文件）
kb-rust --kb-dir <path> add "名称" "类型" "标签1,标签2"
```

## Smoke Test

```bash
cd kb-rust
cargo build --release
BIN=./target/release/kb-rust

# 1) help
$BIN --help
$BIN -h

# 2) init 空库
KB_DIR="$(mktemp -d)"
$BIN --kb-dir "$KB_DIR" init
ls "$KB_DIR"  # 期望：experience/ styles/ plot/ .index.jsonl

# 3) 空库 list/query/search
$BIN --kb-dir "$KB_DIR" list   # Total: 0 entries
$BIN --kb-dir "$KB_DIR" query experience  # 0 entries

# 4) add（生成 Markdown + 写入 .index.jsonl）
$BIN --kb-dir "$KB_DIR" add "Supervisor Tips" experience "supervisor,management"
$BIN --kb-dir "$KB_DIR" list   # Total: 1 entries, experience: 1
$BIN --kb-dir "$KB_DIR" search supervisor  # 1 result

# 5) rebuild（从 Markdown 重建，验证一致性）
$BIN --kb-dir "$KB_DIR" rebuild
$BIN --kb-dir "$KB_DIR" search supervisor  # 仍然 1 result

# 6) 真实数据（audio-comic-skills 知识库）
REAL_KB=/Users/jennyhu/claude-code-source/tasks/audio-comic-skills/knowledge-base
$BIN --kb-dir "$REAL_KB" rebuild  # ✅ Rebuilt: 24 entries
$BIN --kb-dir "$REAL_KB" list       # Total: 24, experience: 20, styles: 2, plot: 2
$BIN --kb-dir "$REAL_KB" search supervisor  # 3 results
$BIN --kb-dir "$REAL_KB" query experience  # 20 entries
```

## 已知限制

- 搜索为全量文本扫描，大规模条目（>10000）性能下降
- rebuild 依赖 Markdown 文件存在，文件丢失则索引不更新
- `entry_type` 字段名兼容：JSONL 中用 `entry_type`，外部 JSON 可能用 `type`

## 目录类型映射

| 目录名 | entry_type |
|--------|------------|
| experience/ | experience |
| styles/ | style |
| plot/ | plot |
| characters/ | character |
| world/ | world |
| voices/ | voice |
