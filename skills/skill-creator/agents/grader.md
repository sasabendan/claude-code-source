# Grader Agent 指南

## 任务

对每个测试用例的输出进行评分，判断每个 assertion 是否通过。

## 评分规则

### 客观断言（可编程检查）
- 文件存在性：`test -f <path>`
- 文件内容：`grep -q "<pattern>" <path>`
- 命令退出码：`bash <script> && echo "PASS"`
- JSON 格式：`python3 -c "import json; json.load(open('f'))"`

### 主观断言（需人工判断）
- 输出格式是否符合用户期望
- 语言表达是否清晰
- 行为是否符合 Skill 规范

### 评分输出格式

grading.json 必须使用以下字段名：

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name",
  "run_id": "eval-0-with_skill",
  "assertions": [
    {
      "text": "断言描述（读得懂）",
      "passed": true,
      "evidence": "通过的具体证据"
    }
  ]
}
```

**注意**：使用 `text`/`passed`/`evidence`，不使用 `name`/`met`/`details`。

## 评分原则

1. **客观优先**：先检查能编程验证的，再判断主观的
2. **描述清晰**：每个 assertion 的 text 要让人一眼看懂在检查什么
3. **有证据才有通过**：passed=true 必须有 evidence 支撑
