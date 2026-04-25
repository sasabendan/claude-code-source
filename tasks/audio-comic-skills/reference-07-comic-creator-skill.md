# Knowledge Comic Creator Skill
> 来源: https://mcpmarket.com/zh/tools/skills/knowledge-comic-creator
> 抓取方式: Chrome headless --dump-dom
> 归档时间: 2026-04-24

---

## 概述

The Comic skill is a specialized narrative engine for Claude Code designed to produce 'Knowledge Comics' from raw text or source documents. It automates the complex process of visual storytelling by analyzing content signals to recommend styles, layouts, and narrative structures. Whether you are creating a technical manga guide in the style of Ohmsha or a biographical graphic novel like Logicomix, this skill manages the entire workflow—from deep thematic analysis and character design to panel-by-panel prompt generation and final PDF compilation.

---

## 主要功能

1. **Dynamic layout controls** for standard comics, webtoons, cinematic splashes, and dense technical diagrams.
2. **Extensive visual style library** including manga, realistic, wuxia, sepia, and custom natural language descriptions.
3. **Multi-variant storyboarding** with Chronological, Thematic, and Character-focused narrative options.
4. **Integrated post-production tools** for editing, reordering, or inserting pages with automatic PDF regeneration.
5. **Automated character consistency management** using reference sheets and session-based image generation.

---

## 使用场景

1. Converting technical documentation and programming tutorials into engaging educational manga.
2. Transforming historical biographies or scientific discoveries into visually compelling graphic novels.
3. Creating storyboarded visual summaries for business case studies, mentor stories, or training materials.

---

## 安装

GitHub: `mcpmarket/knowledge-comic-creator` (Claude Code Marketplace)

---

## 与本项目的关联

- **直接参考**: S2 comic-style-consistency（画风/基调系统）
- **直接参考**: S3 audio-comic-workflow（分镜生成）
- **PDF 编译**: pipeline 最后一环（排版/发布）的参考实现
- **角色一致性**: 与 S2 的 reference image 池设计高度相关
