---
name: kb-auto-linker
description: 知识库自动化双链关联 Skill。当用户说"补全双链"、"添加链接"、"生长图谱"、"补 wikilink"、"消除孤立页面"时触发。也用于 lint 输出孤立页面 > 10 时自动建议调用。
---

# Skill: kb-auto-linker（知识库自动关联）

> 版本：1.1 | 更新：2026-04-26 | 来源：skill-creator 流程 Review 结果

## 核心概念（重要）

**脱孤机制**：一个页面只有在收到 inbound link（别人指向它）时才能脱孤。
- outbound link（我指向谁）→ **不改变孤立状态**
- inbound link（谁指向我）→ **脱孤**

**两种策略**：
1. **给孤立页面加 outbound link**（本次实现）：改善 Obsidian 可导航性，Skills 页面收到 inbound links
2. **给已有页面加指向孤立页的 inbound link**（待实现）：实际消除孤立数

## 触发时机

**语言触发**：
- "补全双链"、"添加链接"、"生长图谱"
- "补 wikilink"、"消除孤立页面"
- "让知识图谱生长"

**自动建议**：lint 输出孤立页面 > 10 时，建议调用本 Skill

## 核心流程 v1

### 策略一（已实现）：给孤立页面加 outbound link

```
① 识别孤立页面
② 分类 → 找相关已有页面
③ 在孤立页面末尾添加 [[wikilinks]]（outbound）
④ rebuild + lint 验证
```

效果：
- Skills 页面收到 inbound links（图谱可导航性 ↑）
- 孤立页面有出链可导航（Obsidian graph 可视化 ↑）

### 策略二（待实现）：给 hub 页面加 inbound link

```
① 找 hub 页面（有声漫画 Skills 全景图、audio-comic-workflow 等）
② 分析孤立页面内容
③ 在 hub 页面末尾添加指向孤立页面的 [[wikilinks]]
④ rebuild + lint 验证
```

**目标**：孤立数 < 10

## 关联策略表

```
kb-rust v1/v2 文档     → [[kb-rust 归档迁移记录]] / [[knowledge-base-manager]]
参考文章               → [[audio-comic-workflow]]
NCA / Pipeline / 漂移   → [[supervision-anti-drift]]
良品率 / 画风 / 角色    → [[self-optimizing-yield]] / [[comic-style-consistency]]
skill-creator          → [[audio-comic-workflow]]
下载文件               → [[knowledge-base-manager]]（判定是否该删除）
```

## 使用示例

```bash
# 运行关联脚本
python3 skills/kb-auto-linker/scripts/auto-link.py

# 验证效果
kb-rust-v2 rebuild --kb-dir knowledge-base
kb-rust-v2 lint --kb-dir knowledge-base
```

## 输出格式

```yaml
skill: kb-auto-linker
orphans_before: 35
links_added: 33   # outbound links added
skills_inbound_improved:
  - audio-comic-workflow: +33 inbound links
  - supervision-anti-drift: +N inbound links
orphans_after: 34  # 策略一不降低孤立数，待策略二
```

## 相关 Skill

- [[knowledge-base-manager]]：关联目标来源
- [[skill-creator]]：触发测试
- [[claude-file-safety]]：下载文件判定（孤立但无价值 → 建议删除）
