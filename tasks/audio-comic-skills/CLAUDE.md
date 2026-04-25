---
name: audio-comic-production
description: 有声漫画自动化生产 Skills 体系主入口。触发词"开始创作有声漫画"后自动完成全流程。
---

# 有声漫画自动化生产 Skills 体系

## 项目概述
- **核心场景**：输入原著文本（小说），输出有声漫画产品
- **触发词**：`开始创作有声漫画`

## Skills 架构

### 核心 Skills（S0-S5）
- **S0** task-book-keeper：任务书管理
- **S1** knowledge-base-manager：知识库管理
- **S2** comic-style-consistency：风格锚定
- **S3** audio-comic-workflow：流水线编排
- **S4** supervision-anti-drift：监督验收
- **S5** self-optimizing-yield：良品率优化

### 行为控制 Skills
- **claude-first-check**：遇到工作要求先查记录再行动（心跳：HEARTBEAT.md → heartbeat-state.md）
- **claude-error-handler**：发生错误/不合理时使用（C17→C19→C20→C23 链条）
- **claude-scope-judge**：行为判定（主任务=边界，边界外需授权）
- **claude-file-safety**：删除文件前判定安全性（主线相关性→上下文→备份→验证）
- **claude-values**：价值观判断（知识库价值层级：待用→可用→可变现；什么重要/该不该做）

## 约束体系（C17-C23 新增）

> **强制原则**：约束之间语义相同或相近者，均受强制约束约束。所有 C 系列同层级强制，无优先级区分。

### C17：遇到不明白 → 查询顺序
①任务书 → ②知识库 → ③上下文 → ④技能 → ⑤本地备份 → ⑥网络搜索 → ⑦带经验问用户

### C19：发现违规 → 记录并修复
①记入 knowledge-base/.index.jsonl ②直接修复，不问用户

### C20：错误范例关键词 ≠ 修改依据
错误范例中的内容不得作为修改约束条件的理由

### C22：错误范例仅作查询依据
不得作为修改依据；修改唯一依据：任务主线

### C23：补技能不补约束
在不违反现有约束的前提下补缺失知识，不得修改约束本身

## 错误范例（已知 Fail Cases）

| 编号 | 错误 | 关键教训 |
|------|------|----------|
| FC001 | WRAP.md 未授权自建 | 不在任务书体系内的文件，红灯 |
| FC002 | C11 Keychain 越权修复尝试 | 错误范例关键词不得改约束 |
| FC003 | backup.sh 密码硬编码 | 违反 C11，已直接修复 |
| FC004 | 执行范围 > 任务书范围 | 绿灯做好，红灯零闯 |

## 授权管理
- 当前授权范围：见 `~/.claude/authorized-scope.jsonl`
- **每日统一授权一次**，未过 24 小时无需重复确认
- 核心原则：主任务 = 边界，边界之外必须取得明确授权

## 关键知识库位置

### 项目知识库（内置）
```
knowledge-base/              # 本项目知识库
knowledge-base/.index.jsonl  # 索引
knowledge-base/experience/   # 经验知识（含参考文献映射）
```

### 参考文献
| 文件 | 内容 |
|------|------|
| `reference-03-rosetears-85.md` | rosetears Supervisor-Worker 框架原文 |
| `reference-06-openspec-630.md` | OpenSpec v0.21.0 vs v1.0 GitHub Issue |

### 下载资源（原始文件）
原始 OpenSpec/Codex/Supervisor 框架资源：
```
/Users/jennyhu/Documents/Claude code - openspec - codex(1)/
```
详情见知识库：`knowledge-base/experience/下载文件_如何使用_md.md`

## OpenSpec/Codex Supervisor 框架
本项目整合了 rosetears Supervisor-Worker 框架用于任务监督验收：
- Supervisor = Claude Code（验收确权）
- Worker = Codex（执行实现）
- 三记忆文件：`tasks.md`、`progress.txt`、`feature_list.json`
- 详情：`knowledge-base/experience/rosetears_supervisor_framework.md`

## 授权管理
- 当前授权范围：见 `~/.claude/authorized-scope.jsonl`
- 每日打卡：主任务未完成前，每天向用户确认授权
- 核心原则：主任务 = 边界，边界之外必须取得明确授权
