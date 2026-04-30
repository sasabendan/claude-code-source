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

