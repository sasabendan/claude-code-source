# kb-rust: LLM Wiki Knowledge Base Manager

## 定位

Rust 重写的知识库管理工具（C1 要求）。管理 LLM Wiki 的 Markdown 文件 + 单一 JSONL 索引入口，零数据库文件。

## 数据架构

```
knowledge-base/
├── .index.jsonl          # 单一索引入口（JSONL，每行一条）
├── experience/           # 经验知识
├── styles/               # 风格参数
├── plot/                 # 剧情结构
├── characters/           # 角色设定（空）
├── world/                # 世界观（空）
└── voices/               # 配音设定（空）
```

## .index.jsonl 格式

每行一个 JSON 条目，字段：

```json
{"entry_type":"experience","name":"知识名称","file":"experience/xxx.md","tags":"tag1,tag2","created":"2026-04-25T00:00:00Z"}
```

字段名：`entry_type` / `name` / `file` / `tags` / `created`

## 编译

```bash
cd kb-rust
cargo build --release
./target/release/kb-rust --help
```

## 命令

```bash
# 初始化目录结构
kb-rust --kb-dir knowledge-base init

# 列出所有条目（按类型统计）
kb-rust --kb-dir <path> list

# 按类型查询
kb-rust --kb-dir <path> query experience

# 搜索名称/标签
kb-rust --kb-dir <path> search supervisor

# 从 Markdown 文件重建索引
kb-rust --kb-dir <path> rebuild

# 追加索引条目
kb-rust --kb-dir <path> add "名称" "类型" "标签1,标签2"
```

## 与旧方案对比

| | JSONL+Markdown（当前） | SQLite（废弃） |
|---|---|---|
| 数据文件 | 只有 .index.jsonl | kb.db + JSONL |
| 备份负担 | 单一文件 | 两份需同步 |
| 维护成本 | 低 | 高 |
| 查询性能 | 中（全文扫描） | 高（B-tree索引） |

## 已知限制

- 搜索为全量文本扫描，大规模条目（>10000）性能下降
- rebuild 从 Markdown 文件读内容，依赖文件存在
- `entry_type` 字段名兼容：JSONL 中用 `entry_type`，外部 JSON 可能用 `type`
