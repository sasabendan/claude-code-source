---
name: self-optimizing-yield
description: 持续优化良品率，实现"贾维斯化"。当生产批次结束后自动触发。核心能力包括良品率指标体系、经验库（Obsidian 双链）、自动调优回路、反馈信号接入、防退化保护。
Do NOT use when: 生产批次尚未结束，或良品率数据不足（C5 未满足）。
---

# Skill: self-optimizing-yield（良品率优化）

## 功能定位
持续积累经验、自动调参、提高下一次良品率。

## 关联约束（C17-C23）

> 本 Skill 须遵守以下约束体系（优先级：约束 > 个人经验）：

| 约束 | 内容 | 执行要点 |
|------|------|---------|
| C17 | 查询顺序 | 遇到不明白 → 任务书 → 知识库 → 上下文 → 技能 → 本地备份 → 网络 → 问用户 |
| C18 | 3 分钟无动作自检 | 继续主线当前节点，不空想 |
| C19 | 发现违规直接修复 | 记录并修复，不问用户 |
| C20 | 错误范例关键词 ≠ 修改依据 | 不得以 Fail Case 中的内容为由修改约束 |
| C22 | 错误范例仅作查询依据 | 不得作修改依据，修改唯一依据：任务主线 |
| C23 | 补技能不补约束 | 在不违反现有约束的前提下补知识，不得修改约束本身 |

## 核心能力

| 能力 | 说明 | 类型 |
|------|------|------|
| 良品率指标 | 分环节统计通过率 | [本地请求] |
| 经验库 | 双链 Markdown 存储 | [本地请求] |
| 自动调优 | 提示词/参数优化 | [网络请求] |
| 反馈接入 | 多源反馈信号 | [网络请求]/[本地请求] |
| 防退化 | 新策略回滚保护 | [本地请求] |

## 输入

```yaml
production_run_id: <生产批次 ID>
artifacts: <各环节产物路径>
feedback: <反馈信号，可为空>
```

## 输出

```yaml
yield_metrics: <分环节良品率>
new_patterns: <可复用模式列表>
updated_prompts: <更新的提示词>
rollback_triggered: true|false
next_run_config: <推荐配置>
```

## 触发场景
每次生产批次结束后自动触发。

## 良品率指标

```yaml
yield_rate = 一次通过数 / 总生产数

分环节统计:
  - 脚本通过率
  - 分镜通过率
  - 生图通过率
  - 配音通过率
  - 合成通过率

目标: 每周环比提升 ≥3%，直到 ≥95%
```

## 经验库结构

```
experience-vault/
├── failure-cases/
│   └── [[failure-case-YYYYMMDD-HHMM]]
├── patterns/
│   └── [[pattern-lib]]
└── templates/
    └── [[prompt-templates]]
```

## 优化回路

```
失败案例 → 归因分析 → 生成新 prompt → A/B 测试 → 胜出者入库
```

## 防退化保护

```yaml
rollback_conditions:
  - 连续 3 次不如旧策略
  - 金标准测试集不通过
  - 良品率下降 >10%
```

## 参考资料

- eugeniughelbur/obsidian-second-brain（反馈闭环）
- JimLiu/baoyu-skills（经验沉淀）

## 验收标准

- [ ] 结构化 yield_metrics 产出
- [ ] 至少 1 条经验入库
- [ ] 更新的提示词通过测试
- [ ] 回滚机制有效
- [ ] Obsidian 双链格式兼容

## 代码入口

`skills/self-optimizing-yield/scripts/yield-optimizer.sh`

---

## 扩展：Extraction Quality Tracking（2026-04-30）

### 新增追踪指标

在良品率追踪体系中，增加 LangExtract 提取质量指标。

### 新增指标

```yaml
extraction_quality:
  grounding_rate:
    description: "char_interval 覆盖率"
    tracking: "per_chapter"
    target: "≥ 95%"
    
  ungrounded_rate:
    description: "无效提取比例"
    tracking: "per_chapter"
    target: "≤ 5%"
    
  class_distribution:
    description: "提取类型分布（character/dialogue/scene/sfx）"
    tracking: "per_project"
    
  repeat_extraction_rate:
    description: "重复提取比例（同一 character 多次出现时）"
    tracking: "per_chapter"
    target: "≤ 10%"
```

### 优化回路

```
每批次完成后：
1. 统计 extraction_quality 指标
2. 与历史平均对比
3. 如果指标下降 → 分析原因
   - grounding_rate 下降 → 检查 prompt 描述
   - repeat_extraction_rate 上升 → 检查 character dedup 逻辑
4. 更新 prompt_templates 中的 extraction 模板
```

### 经验库新增

```markdown
experience-vault/
├── extraction-patterns/           # 新增目录
│   ├── [[extraction-grounding-fail]]       # grounding 失败案例
│   ├── [[extraction-character-dedup]]       # character 去重逻辑
│   └── [[extraction-long-doc-optimization]] # 长文档优化
```


---

## 扩展：基于 claude-mem 的自动蒸馏（2026-04-30）

### 自动蒸馏触发时机

参考 claude-mem 的 PostToolUse 钩子，在以下时机自动蒸馏：

```yaml
triggers:
  - PostToolUse: Bash(script-generation)
    action: distill_script_params → knowledge-base

  - PostToolUse: Bash(image-generation)
    action: distill_style_params → kb-rust

  - PostToolUse: Bash(audio-generation)
    action: distill_voice_params → Character_Voice_Preset

  - PostToolUse: Supervisor verify PASS
    action: distill_success_pattern → experience-vault

  - Stop: SessionEnd
    action: distill_session_summary → progress.txt
```

### 三层索引蒸馏流程

```
工具执行完成（PostToolUse）
         ↓
Level 1: 提取关键词/标签 → Meta-Index（内存）
         ↓
Level 2: 生成语义摘要 → Summary（SQLite + char_interval）
         ↓
Level 3: 原始参数存档 → Raw Context（按需加载）
         ↓
更新 kb-rust 三层索引
```

### 蒸馏质量追踪

```yaml
distillation_quality:
  token_savings:
    description: "Progressive Disclosure Token 节省率"
    target: "≥ 80%"

  char_interval_accuracy:
    description: "原文溯源准确率"
    target: "≥ 95%"

  observation_count:
    description: "每批次蒸馏的 observation 数量"
    tracking: "per_run"
```

---

## 扩展：ce-compound 复利飞轮（2026-04-28）

参考 EveryInc/compound-engineering-plugin 的 `/ce-compound` 机制，作为良品率优化的核心复利循环。

### ce-compound 飞轮流程

```
批次完成 → 问题捕获 → 5维重叠检测 → 经验文档沉淀
                                    ↓
                              下一批次调用
                                    ↓
                              再优化 → 再沉淀（飞轮闭环）
```

### 经验文档结构（docs/solutions/ 格式）

```yaml
---
title: "[P3] 风格一致性下降 - 批次 #42"
category: optimization        # bug-fix | optimization | feature | refactor | research
difficulty: medium           # trivial | easy | medium | hard | epic
outcome: P3 风格一致性从 0.72 提升至 0.91
references: []
related_issues: []
prevention_rules:
  - 每次生图前检查 LoRA 权重是否在 [0.7, 0.9] 范围内
  - 批次开始前校验 character visual_features 完整性
---
```

### 5维重叠检测

评估新经验与现有经验的重叠程度：

| 维度 | 评估内容 | ≥3维时操作 |
|------|---------|-----------|
| problem_statement | 问题类型相同？ | 合并到现有文档 |
| root_cause | 根本原因相同？ | 覆盖现有文档 |
| solution_approach | 解决方案相同？ | 交叉引用 |
| referenced_files | 涉及文件相同？ | 更新现有文档 |
| prevention_rules | 预防规则相同？ | 合并规则 |

### 与 S4/Rigor Gaps 对齐

批次经验文档中增加 Rigor Gaps 校验结论：

```yaml
---
rigor_gaps_assessment:
  premise_check: "LoRA 权重范围假设验证 ✓"
  dependency_check: "MiniMax API 可用性确认 ✓"
  boundary_check: "极端长文本场景未覆盖 → 加入 long-doc test"
  logic_chain_check: "情感参数传递链路自洽 ✓"
---
```

