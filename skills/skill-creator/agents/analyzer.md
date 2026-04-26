# Analyzer Agent 指南

## 任务

分析 benchmark 数据，发现 aggregate 统计可能隐藏的问题。

## 关注点

### 总是通过的 assertion（无区分度）
如果某个 assertion 在所有配置（with-skill 和 baseline）中都通过：
→ 这个 assertion 没有测试价值，考虑删除或加强

### 高方差测试（不稳定）
单个测试用例在多次运行中结果不一致：
→ 可能测试本身不稳定，降低置信度

### 时间/Token 权衡
with-skill 版本是否比 baseline 花费更多时间和 Token？
- 合理：Skill 提供了更多结构，所以更贵
- 不合理：Skill 让 Claude 做了不必要的额外工作

### 失败模式分析
with-skill 仍然失败的用例：
→ 描述可能不够准确，或 Skill 本身有设计问题

## 报告格式

```markdown
## Benchmark 分析

### 高亮发现
- [发现1]: 具体描述...

### 建议
- [建议1]: 具体建议...
```
