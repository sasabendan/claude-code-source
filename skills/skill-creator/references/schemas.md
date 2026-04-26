# Skill 相关的 JSON Schema 规范

## evals.json 结构

```json
{
  "skill_name": "string",
  "version": "string",
  "created": "YYYY-MM-DD",
  "description": "string",
  "evals": [
    {
      "id": 0,
      "prompt": "string（用户实际会说的话）",
      "should_trigger": true | false,
      "category": "string（分类）",
      "expected_behavior": "string（期望行为描述）",
      "assertions": [
        {
          "name": "string",
          "description": "string"
        }
      ]
    }
  ]
}
```

## grading.json 结构

```json
{
  "eval_id": 0,
  "eval_name": "string",
  "run_id": "eval-0-with_skill",
  "passed": true | false,
  "assertions": [
    {
      "text": "string（断言描述）",
      "passed": true | false,
      "evidence": "string（证据）"
    }
  ]
}
```

## benchmark.json 结构

```json
{
  "skill_name": "string",
  "iteration": 1,
  "results": [
    {
      "run_id": "eval-0-with_skill",
      "pass_rate": 0.85,
      "avg_tokens": 12000,
      "avg_duration_ms": 23000
    }
  ],
  "summary": {
    "with_skill_pass_rate": 0.92,
    "baseline_pass_rate": 0.60,
    "delta": 0.32,
    "with_skill_mean_time_ms": 24000,
    "baseline_mean_time_ms": 18000
  }
}
```

## eval_metadata.json 结构

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

## feedback.json 结构

```json
{
  "reviews": [
    {
      "run_id": "eval-0-with_skill",
      "feedback": "string（用户反馈）",
      "timestamp": "ISO8601"
    }
  ],
  "status": "complete"
}
```
