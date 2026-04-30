---
name: kb-rust v2 开发日志
entry_type: experience
created: 2026-04-25T23:59:05.330630+00:00
updated: 2026-04-25T23:59:05.330630+00:00
tags: [kb-rust,v2,changelog,bug-fix]
status: stable
---

# kb-rust v2 开发日志

> 源文件：`kb-rust/v2/CHANGELOG.md`

## v2.1.1 - 2026-04-26

### 基建稳定化：入口不漂移

- **add 后 auto-rebuild**：`add` 执行完自动触发 rebuild，`.index.jsonl` 和 `_index.md` 永远同步
- **ingest 后 auto-rebuild**：摄入新源文件后立即更新入口索引
- **init 非破坏性补全**：对已有库运行 `init` 只补全缺失内容，不破坏现有文件
- **WORKFLOW.md 创建**：双链最低标准（角色≥3、剧情/概念≥2、参考文章≥1）+ 入口索引 + 三层架构 + 同步保证

## v2.1.0 - 2026-04-25

### 新增需求 R11：错误自动记录

- 来源：TASK_REQUIREMENTS.md C19「发现违规 → 记录并修复」
- 态控设计：调试态默认开启（写 fail-case 到 .index.jsonl），运行态关闭（仅 stderr）
- 待实现：errors 命令 / lint 输出 fail case 计数 / 各命令错误捕获点接入

## v2.0.1 - 2026-04-25

### Bug Fixes（用户测试反馈）

- **rebuild: 空 name 回退到文件名**：无 frontmatter 又无 `# 标题` 的 MD 文件（如 karpathy_llm_wiki_original.md）导致 name="" 脏条目 → 修复：自动使用文件名（去掉 .md）作为 name
- **ingest: 错误信息补充说明**：仅 .md 时报错改为「未来支持 .txt/.pdf/.epub/.docx」
- **lint: 增加 bad entries 计数**：输出「BAD entries (empty name): N」

### 测试结果
```
✅ rebuild：karpathy_llm_wiki_original.md → name="karpathy_llm_wiki_original"（文件名回退）
✅ query experience：首行不再是 | 空记录
✅ ingest .txt：报错信息清晰，预告未来支持格式
✅ lint：bad_entries=0（回退策略生效）
```

## v2.0.0 - 2026-04-25

### 架构变更

- v1 混沌结构 → Karpathy 三层架构（Raw Sources / Wiki / Schema）
- 新增 .project.json / _backlinks.json / _compiled/（_index.md + _log.md + _overview.md）
- 新增命令：workflow / chars / backlinks / ingest / lint / project-info
- rebuild 扩展：扫描 MD + 双链解析 + _compiled 更新

## v1.0.0 - 2026-04-24

- 从 SQLite 版本重建，引入 JSONL 索引
- 6 命令：init / add / list / query / search / rebuild
- frontmatter 解析：name / created / tags（YAML 数组或逗号分隔）

## 相关链接
- [[kb-rust 归档迁移记录]]
- [[knowledge-base-manager]]
- [[kb-rust v2]]
