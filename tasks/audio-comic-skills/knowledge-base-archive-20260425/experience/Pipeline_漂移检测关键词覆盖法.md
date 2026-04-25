---
type: experience
name: Pipeline 漂移检测关键词覆盖法
created: 2026-04-25T02:55:35Z
tags: [drift, detection, pipeline]
---

## Pipeline 漂移检测关键词覆盖法

### 定位
用关键词覆盖率判断 Worker 产出是否偏离原始任务 spec。

### 方法
1. 从 spec 提取关键词（中文 + 英文，≥2 字符）
2. 在 Worker 产出中统计覆盖率
3. 覆盖率 < 阈值（默认 85%）→ 漂移检测失败

### Python 实现
```python
import re
keywords = re.findall(r'[\u4e00-\u9fa5a-zA-Z]{2,}', spec)
kw_set = sorted(set(kw.lower() for kw in keywords))
coverage = matched / len(kw_set) if kw_set else 0
drift_val = 1 - coverage
```

### macOS bash 3.2 限制
- grep 对中文匹配有 bug
- 不支持 `declare -A`（关联数组）
- 解法：用 Python 写 drift 检测逻辑，bash 只做调用和结果展示

### 原文位置
`skills/supervision-anti-drift/scripts/supervisor.sh`（已实现）

