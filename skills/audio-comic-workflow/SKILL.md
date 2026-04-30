---
name: audio-comic-workflow
description: 有声漫画全流程编排引擎，是主触发入口。当用户说"开始创作有声漫画"时触发。核心能力是 7 环节流水线编排：脚本 → 分镜 → 生图 → 配音 → 合成 → 排版 → 发布。支持断点续跑，全自动可中断。
Do NOT use when: 用户只是想查询某个具体环节的信息，而非启动完整流水线。
---

# Skill: audio-comic-workflow（有声漫画工作流）

## 功能定位
有声漫画全流程编排引擎，主触发入口。

## 项目上下文（CWD 自适应）

本 Skill 不依赖 CLAUDE.md 读取上下文，直接内嵌配置：

```
知识库路径：CWD 自适应
  ① $AUDIO_COMIC_KB（环境变量，最高优先）
  ② ./knowledge-base/
  ③ ./tasks/*/knowledge-base/
  ④ ../tasks/*/knowledge-base/

风格参数：CWD 自适应
  ① ./knowledge-base/styles/
  ② ./tasks/*/knowledge-base/styles/

任务书：
  ① ./TASK_REQUIREMENTS.md
  ② ./tasks/*/TASK_REQUIREMENTS.md

触发词：开始创作有声漫画
```

## 核心能力

| 能力 | 说明 | 类型 |
|------|------|------|
| 流水线编排 | 7 环节有序执行 | [本地请求] |
| 断点续跑 | 中断后可继续 | [本地请求] |
| 并行处理 | 独立环节并行 | [本地请求] |
| 状态追踪 | checkpoint 记录 | [本地请求] |

## 输入

```yaml
action: start|resume|pause|status
source: <原著文本路径>
chapter: <章节号，可选>
checkpoint_id: <断点 ID，可选>
```

## 输出

```yaml
status: running|paused|completed
current_step: <当前环节>
progress: <进度百分比>
artifacts: <各环节产物>
```

## 触发场景

**主触发词**：`开始创作有声漫画`

## 7 环节流水线

```
┌─────────────────────────────────────────────────────────────┐
│                    有声漫画生产流水线                          │
├─────────────────────────────────────────────────────────────┤
│  1. 脚本生成 → 2. 分镜设计 → 3. 生图 → 4. 配音            │
│                     ↓                                       │
│  5. 合成 → 6. 排版 → 7. 发布                              │
└─────────────────────────────────────────────────────────────┘
```

### 环节详情

| 环节 | 输入 | 输出 | 依赖 Skill |
|------|------|------|-----------|
| 1. 脚本生成 | 原著文本 | 分镜脚本 | S1 知识库 |
| 2. 分镜设计 | 脚本 | 分镜描述 | S2 风格锚定 |
| 3. 生图 | 分镜描述 | 漫画图片 | S2 风格锚定 |
| 4. 配音 | 脚本 | 音频文件 | S2 声音一致 |
| 5. 合成 | 图片+音频 | 视频 | S4 资源调度 |
| 6. 排版 | 视频 | 成品 | - |
| 7. 发布 | 成品 | 发布结果 | S1 知识库 |

## 断点续跑机制

```yaml
checkpoint:
  id: <唯一 ID>
  step: <当前环节>
  input: <环节输入>
  output: <环节输出>
  timestamp: <时间戳>
```

### 续跑流程

```
中断 → 保存 checkpoint
    ↓
恢复 → 读取 checkpoint
    ↓
继续 → 从断点继续执行
```

## 参考资料

- JimLiu/baoyu-skills（工作流编排）
- rosetears.cn/archives/85/（断点续跑机制）

## 验收标准

- [ ] 7 环节流水线可执行
- [ ] 断点续跑功能正常
- [ ] 各环节产物可追溯
- [ ] 支持并行处理

## 代码入口

`skills/audio-comic-workflow/scripts/workflow-engine.sh`

---

## 扩展：Stage 0 剧本预提取（2026-04-30）

### 新增阶段

在原有 7 环节流水线之前，增加 Stage 0：剧本结构化预提取。

```
Stage 0: LangExtract 预提取（新增）
  ↓
P1: 脚本生成
  ↓
P2: 分镜设计
  ↓
P3: 生图渲染
  ↓
P4: 配音合成
  ↓
P5: 成品合成
  ↓
P6: 排版发布
```

### Stage 0 流程

```
1. 接收原著文本（路径或 URL）
2. 调用 langextract-pre.sh
3. 提取：character / dialogue / scene / sfx
4. 输出：extractions.jsonl + visualization.html
5. 质量检查：char_interval 覆盖率 ≥ 95%
6. 写入 evidence/run-<N>/extractions/
```

### 输入

```yaml
stage: 0
action: pre-extract
source: <原著文本路径 或 URL>
model: gemini-2.5-flash  # 推荐，默认
extraction_passes: 3     # 长文档用 3 次
```

### 输出

```yaml
status: success
extractions_file: <evidence_dir>/extractions.jsonl
visualization: <evidence_dir>/extraction_visualization.html
grounding_rate: 0.97     # char_interval 覆盖率
character_count: 12
dialogue_count: 45
scene_count: 8
sfx_count: 5
```

### NCA 必要条件

| 指标 | 阈值 |
|------|------|
| grounding_rate | ≥ 95% |
| character 有 name | 100% |
| dialogue 有 emotion | 100% |
| scene 有 visual_prompt_sd | 100% |
| sfx 有 timing | 100% |

### 失败处理

Stage 0 NCA 不满足 → 不进入 P1 → 修复提取结果后重试

### 相关 Skill

- [[knowledge-base-manager]]：提供 langextract-pre.sh
- [[supervision-anti-drift]]：Stage 0 验收

