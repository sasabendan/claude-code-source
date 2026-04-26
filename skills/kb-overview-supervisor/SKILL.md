---
name: kb-overview-supervisor
description: 知识库全景区图监工 Skill。所有知识库相关操作之前必须调用，确保动作不跑偏。触发词："查全景图"、"知识库管理"、"补双链"、"消除孤立"、"管理知识库"、"查看 Skill 状态"、"KB 状态"、"回到主线"。当不确定某个 KB 操作是否正确时，调用本 Skill 做判断。
---

# Skill: kb-overview-supervisor（全景区图监工）

> 版本：1.0 | 创建：2026-04-26
> 定位：KB 管理的"监工"，确保所有知识库动作经过正确 Skill，不跑偏

## 核心职责

**KB 监工（Supervisor）**——任何知识库相关操作之前，激活本 Skill 做判断。

```
用户/Claude 准备执行 KB 操作
     ↓
kb-overview-supervisor 激活
     ↓
判断：该用哪个 Skill？有没有越权？
     ↓
执行正确的 Skill
```

## 决策矩阵

| 操作意图 | 应调用的 Skill | 禁止行为 |
|---------|--------------|---------|
| 添加条目 | [[knowledge-base-manager]] add | 直接写文件不记录索引 |
| 消除孤立页面 | [[kb-auto-linker]] | 给孤立页面加 outbound link 后误以为脱孤 |
| 加密备份 | [[encrypted-backup]] | 删除本地 .md（HC-AP1） |
| 删除文件 | [[claude-file-safety]] + [[core-asset-protection]] | 未判定红灯就删除 KB 管理的文件 |
| 新建 Skill | [[skill-creator]] | 直接写 SKILL.md 不走 skill-creator 流程 |
| 补全双链 | [[kb-auto-linker]] | outbound link ≠ 脱孤（必须是 inbound） |
| 查看 KB 状态 | `kb-rust-v2 lint` | 不运行 lint 就开始操作 |

## 判断标准

### 红灯（禁止执行）

- KB 相关操作绕过了正确 Skill
- 给孤立页面加链接后声称"脱孤"（outbound ≠ inbound）
- 删除本地明文核心资产文件
- 加密推送 GitHub 后删除本地 .md
- 密码明文出现在任何文件

### 绿灯（可以执行）

- 操作经过正确的 KB Skill
- 删除前执行了 claude-file-safety 判定
- 加密前确认 HC-AP1（本地明文永远保留）
- 新建/修改 Skill 前调用 skill-creator

## 触发检查清单

每次 KB 操作前自问：

```
① 用对了 Skill 吗？（knowledge-base-manager / kb-auto-linker / encrypted-backup / skill-creator）
② 有没有越权？（直接操作文件而不走 Skill）
③ 有没有违反 HC-AP1/2/3？
④ 操作后运行 lint 验证了吗？
```

## 全景区图内容索引

完整全景图：`knowledge-base/experience/有声漫画-Skills-全景图.md`

| 类别 | 数量 | 关键 Skill |
|------|------|-----------|
| 生产技能 | 5 | audio-comic-workflow |
| 元技能 | 6 | skill-creator / claude-error-handler |
| 工具技能 | 10 | kb-auto-linker / core-asset-protection / encrypted-backup |
| **合计** | **21** | |

## 已知漂移模式（防止重复犯错）

| 漂移类型 | 错误做法 | 正确做法 |
|---------|---------|---------|
| FC004 教训 | 加密推送后删除本地 .md | GitHub .enc + 本地 .md 并行保留 |
| outbound ≠ inbound | 给孤立页加出链后误以为脱孤 | inbound link 才是脱孤条件 |
| 越权写文件 | 直接写 SKILL.md | 走 skill-creator 流程 |
| 跳过 lint | 直接操作不验证 | lint 后操作，lint 后验证 |

## 输出格式

```yaml
skill: kb-overview-supervisor
judgment: APPROVED / BLOCKED
reason: <判断理由>
called_skill: <应调用的 Skill>
hc_check: PASS/FAIL (HC-AP1/2/3)
next_action: <下一步操作>
```

## 相关 Skill

- [[knowledge-base-manager]]：执行添加/查询/搜索
- [[kb-auto-linker]]：执行双链关联（注意脱孤机制）
- [[encrypted-backup]]：执行加密备份（HC-AP1 强制）
- [[core-asset-protection]]：前置 Skill，守护 HC-AP1/2/3
- [[claude-file-safety]]：删除前判定
- [[skill-creator]]：新建/优化 Skill
- [[claude-error-handler]]：FC004 等错误记录（C17→C19）
