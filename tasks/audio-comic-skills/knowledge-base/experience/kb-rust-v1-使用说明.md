---
name: kb-rust v1 使用说明
entry_type: experience
created: 2026-04-26T00:23:03.560368+00:00
updated: 2026-04-26T00:23:03.560368+00:00
tags: [kb-rust,v1,manual,smoke-test,目录映射]
status: stable
---

# kb-rust v1 使用说明

> 源文件：`kb-rust/archive/v1/README.md`
> 版本：v1.0 | 更新：2026-04-25

## 定位

Rust 重写的知识库管理工具（C1 要求）。管理 LLM Wiki 的 Markdown 文件 + 单一 JSONL 索引入口，零数据库文件。

## 数据架构

```
knowledge-base/
├── .index.jsonl          # 单一索引入口（JSONL，每行一条）
├── experience/           # 经验知识
├── styles/               # 风格参数
├── plot/                 # 剧情结构
├── characters/           # 角色设定
├── world/                # 世界观
└── voices/               # 配音设定
```

## Markdown 格式（rebuild 可解析）

- `name`：取文件第一行的 `# 标题`（去掉 `# ` 前缀）
- `tags`：取所有以 `tags:` 开头的行（逗号拼接）
- `created`：取第一条以 `created:` 开头的行
- `entry_type`：根据 Markdown 文件所在的父目录名推断

## .index.jsonl 格式

```json
{"entry_type":"experience","name":"知识名称","file":"experience/xxx.md","tags":"tag1,tag2","created":"2026-04-25T00:00:00Z"}
```

## 命令（v1）

```bash
kb-rust --kb-dir knowledge-base init      # 初始化目录结构
kb-rust --kb-dir knowledge-base list      # 列出所有条目（按类型统计）
kb-rust --kb-dir knowledge-base query experience  # 按类型查询
kb-rust --kb-dir knowledge-base search supervisor  # 全文搜索（大小写不敏感）
kb-rust --kb-dir knowledge-base rebuild   # 从 Markdown 文件重建索引
kb-rust --kb-dir knowledge-base add "名称" "类型" "标签1,标签2"  # 追加条目
```

## Smoke Test

```bash
cd kb-rust && cargo build --release
BIN=./target/release/kb-rust
KB_DIR="$(mktemp -d)"
$BIN --kb-dir "$KB_DIR" init
$BIN --kb-dir "$KB_DIR" add "Supervisor Tips" experience "supervisor,management"
$BIN --kb-dir "$KB_DIR" list   # Total: 1 entries
$BIN --kb-dir "$KB_DIR" rebuild
```

## 目录类型映射

| 目录名 | entry_type |
|--------|------------|
| experience/ | experience |
| styles/ | styles |
| plot/ | plot |
| characters/ | characters |
| world/ | world |
| voices/ | voices |

## 已知限制

- 搜索为全量文本扫描，大规模条目（>10000）性能下降
- rebuild 依赖 Markdown 文件存在，文件丢失则索引不更新
- `entry_type` 字段名兼容：JSONL 中用 `entry_type`，外部 JSON 可能用 `type`

## 版本记录

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-04-24 | v1.0 | 初始版本，6 命令（init/add/list/query/search/rebuild），Markdown+JSONL 架构 |
| 2026-04-25 | v2.0 | 归档，v1 锁定不动 |