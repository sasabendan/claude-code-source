# pi-mono 技术参考

> 来源：https://github.com/badlogic/pi-mono
> 学习时间：2026-04-30
> 相关性：多模型调度、多 Agent 状态管理、TUI 监控

## 核心包

| 包 | Stars | 功能 | 借鉴点 |
|---|------|------|--------|
| pi-ai | 高 | 多供应商 LLM API 统一接口 | 多模型动态切换 |
| pi-agent-core | 高 | Agent 运行时 + 状态管理 | 多 Agent 上下文维护 |
| pi-tui | 中 | Terminal UI 库 | 流水线监控仪表盘 |
| pi-mom | 低 | Slack bot | 微信端联通参考 |

## pi-ai 多模型调度设计

```
同一套代码，根据任务性质动态切换模型：

Task → pi-ai → 
  ├─ 本地 oLLM（简单任务，成本低）
  ├─ Claude（复杂逻辑，高质量）
  └─ MiniMax（批处理，成本优先）

模型选择策略：
  - 简单分镜描述 → oLLM
  - 复杂剧情编排 → Claude
  - 批量生图提示词 → MiniMax
```

## pi-agent-core 状态管理

```
多 Agent 协作时的状态流转：

Worker-A → 状态更新 → pi-agent-core → 状态同步 → Worker-B
                              ↓
                         持久化到磁盘
                              ↓
                         上下文不丢失

适合场景：
  - 有声漫画流水线（长流程，容易丢失上下文）
  - 多 Agent 并行（状态需要同步）
```

## 集成计划

| 时间 | 任务 |
|------|------|
| 本周 | 研究 pi-ai API 设计，集成到 audio-orchestrator |
| 下周 | 基于 pi-tui 设计流水线监控 TUI |
| 下月 | 接入 pi-agent-core，实现真正的多 Agent 自动化 |

## 已知限制

- TypeScript/npm 环境，与现有 bash 脚本不同
- 作为外部工具链，不影响现有 Skill
- 需要额外学习成本
