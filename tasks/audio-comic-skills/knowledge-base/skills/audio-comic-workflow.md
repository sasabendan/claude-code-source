---
name: audio-comic-workflow
entry_type: skills
created: 2026-04-26T00:40:01.225657+00:00
updated: 2026-04-26T00:40:01.225657+00:00
tags: [pipeline,workflow,7环节,断点续跑,S1]
status: stable
---

# audio-comic-workflow（有声漫画工作流）

> 主触发入口 Skill。当用户说「开始创作有声漫画」时触发。
> 源码：`skills/audio-comic-workflow/SKILL.md`

## 7 环节流水线

```
脚本生成 → 分镜设计 → 生图 → 配音 → 合成 → 排版 → 发布
```

| 环节 | 输入 | 输出 | 依赖 Skill |
|------|------|------|-----------|
| 1. 脚本生成 | 原著文本 | 分镜脚本 | S1 知识库 |
| 2. 分镜设计 | 脚本 | 分镜描述 | S2 风格锚定 |
| 3. 生图 | 分镜描述 | 漫画图片 | S2 风格锚定 |
| 4. 配音 | 脚本 | 音频文件 | S2 声音一致 |
| 5. 合成 | 图片+音频 | 视频 | S4 资源调度 |
| 6. 排版 | 视频 | 成品 | — |
| 7. 发布 | 成品 | 发布结果 | S1 知识库 |

## 断点续跑

- checkpoint 记录每个环节的输入/输出
- 中断后可从断点继续，无需从头
- 代码入口：`skills/audio-comic-workflow/scripts/workflow-engine.sh`
