# 任务需求表：有声漫画自动化生产 Skills 体系
## v0.7 | 2026-04-30

---

## 一、项目概述

### 核心场景
**来料加工**：输入是原著文本（小说、超长篇），输出是有声漫画产品。

### 生产流程思维
```
【Stage 0】LangExtract 预提取 → 角色/对白/场景/SFX 结构化提取
    ↓
【Step 1】顺着原著的故事线、世界线、作品调性 → 打磨剧本
    ↓
【Step 2】细节标注 + 知识库搭建 → 尊重原著
    ↓
【Step 3】流水线分工协作 → 分镜/生图/配音/合成/排版
    ↓
【Step 4】产出合格产品 → 有声漫画
    ↓
【持续】良品率追踪 → 不断提升 → 质量可靠的作品
```

> **阶段说明**：Stage 0 是所有后续 Worker 的结构化输入，为 Supervisor-Worker 架构提供 Startup Ritual 的可读档案基础。

### 关键词
| 关键词 | 含义 |
|--------|------|
| **来料加工** | 基于原著二次加工，不是凭空创作 |
| **尊重原著** | 顺着故事线、世界观、作品调性 |
| **流水线** | 分工协作，不是 AGI 协商 |
| **良品率** | 从合格开始，不断提升 |
| **核心资产** | 流水线协作方式 + 核心技能优化 + **任务书**，禁止外传 |
| **任务书迭代** | 每周审视，持续优化 |
| **证据链优先** | 没有证据 = 没有完成，Agent 自我声称不等于真实产出 |
| **职责正交化** | 写的不验，验的不写，Supervisor 和 Worker 角色严格分离 |
| **Startup Ritual** | 每个 Worker 启动前必须读取历史档案并写入 logs/startup.txt |

---

## 二、交付物功能总览

| 组合功能 | 说明 |
|---------|------|
| **自身任务管理** | 任务书管理、进度追踪、记忆保留与迭代 |
| **全流程自动化** | 脚本→分镜→生图→配音→合成→排版→发布，全自动可中断续跑 |
| **风格一致性** | 画面风格锚定 + 声音音色固定，跨生成保持一致 |
| **多模型智能调度** | 单任务单模型，成本优先 |
| **监督验收机制** | checkpoint 回滚，NCA 必要条件阻断 |
| **自我优化能力** | 良品率追踪，经验沉淀，防退化保护 |

---

## 三、六大 Skills 功能分工与参考来源

### Skill 0: task-book-keeper
| 项目 | 内容 |
|------|------|
| **功能定位** | 任务书管理与核心记忆保留迭代 |
| **核心能力** | 任务书加密存储；版本管理；每周审视；核心记忆保留与迭代 |
| **触发场景** | "审视任务书"/"更新理解"/"记录进展"/"保留记忆" |

### Skill 1: knowledge-base-manager
| 项目 | 内容 |
|------|------|
| **功能定位** | 本地知识库：原著细节、世界观、角色设定记录 |
| **核心能力** | 得到笔记 OpenAPI [网络] + GitHub 双源；增量式 Wiki 架构；Obsidian 双链格式 |
| **参考来源** | ① 得到笔记 API ② Astro-Han/karpathy-llm-wiki ③ eugeniughelbur/obsidian-second-brain |

### Skill 2: comic-style-consistency
| 项目 | 内容 |
|------|------|
| **功能定位** | 解决 AI 生图/配音的风格漂移问题 |
| **核心能力** | 角色/场景/画风锚定 [本地]；声音一致性 [网络/本地] |
| **参考来源** | ① JimLiu/baoyu-skills ② eugeniughelbur/obsidian-second-brain |

### Skill 3: audio-comic-workflow
| 项目 | 内容 |
|------|------|
| **功能定位** | 流水线编排引擎（主编 Agent，主触发入口） |
| **核心能力** | 7 环节流水线：脚本→分镜→生图→配音→合成→排版→发布；断点续跑 |
| **Supervisor-Worker 架构** | 主编 Agent = Supervisor；各环节执行 Agent = Worker；每个环节独立验收 |
| **触发场景** | **"开始创作有声漫画"** |
| **参考来源** | ① JimLiu/baoyu-skills ② rosetears.cn/archives/85/ |

### Skill 4: supervision-anti-drift
| 项目 | 内容 |
|------|------|
| **功能定位** | 所有环节的监督验收（主编 Agent 执行层） |
| **核心能力** | Supervisor 角色；Startup Ritual；双层账本；Immutable Run Folder；HARD GATE；NCA 必要条件阻断 |
| **强制约束** | `openspec==0.21.0` 禁止升级 |
| **参考来源** | ① rosetears.cn/archives/85/ ② rosetears.cn/archives/55/ ③ OpenSpec #630 |

### Skill 5: self-optimizing-yield
| 项目 | 内容 |
|------|------|
| **功能定位** | 持续优化良品率 |
| **核心能力** | 良品率指标体系；经验库；自动调优回路；防退化保护 |

---

## 四、约束清单

> **强制原则：约束之间语义相同或相近者，均受强制约束约束。不得以"不同编号"为由选择性适用；不得以"另一条更具体"为由规避；所有约束同层级强制，无优先级区分。**

| # | 约束类型 | 内容 |
|---|---------|------|
| **C0** | **定时备份** | 每 5 分钟自动备份当前任务进度到本地 |
| **C0.1** | **GitHub 备份** | 每次备份同步到 GitHub（加密） |
| **C9** | **参考对照** | 每个 Skill 产出前标注参考资料编号 |
| **C10** | **核心资产保护** | 任务书 + 流水线协作方式 + 核心技能优化 = 禁止外传 |
| **C11** | **备份加密策略** | 每 5 分钟一次 GitHub 自动备份，密码 omlx2046（user 主动提及），无需反复授权；主线任务相关技能/任务书/知识库备份必须加密；本地备份不加密，做好版本管理；不主动修改约束条件 |
| **C12** | **本地维护** | 定期磁盘清理；协作方配置管理 |
| **C13** | **任务书迭代** | 每周审视任务书，主动优化 |
| **C14** | **核心记忆保留** | 每次会话后保留关键理解 |
| C1 | 技术栈 | 新代码用 Rust |
| C2 | 标注规范 | 标注 `[网络请求]` 或 `[本地请求]` |
| C3 | 模型选型 | 单任务单模型，成本优先 |
| C4 | 监督机制 | NCA 必要条件不达标即阻断 |
| C5 | 版本锁定 | `openspec==0.21.0` 禁止升级 |
| C6 | 成本上限 | Skill 4+5 不超过生产成本 20% |
| C7 | 审计要求 | 全量落盘 |
| C8 | 可复现性 | 可 hash 校验，失败可回滚 |
| **C15** | **分叉任务管理** | **任何分叉任务完成后，必须回到主线任务** |
| **C16** | **优先现有条件** | **能用现有条件就用现有条件，除非能效差别巨大或资源占用相差巨大** |
| **C17** | **遇到不明白/不理解/不合理 → 查询顺序** | ① 任务书（TASK_REQUIREMENTS.md / TASK_PROGRESS.md）→ ② 知识库（knowledge-base/.index.jsonl）→ ③ 上下文（WRAP.md / CLAUDE.md / master-plan.md）→ ④ 技能（各 Skill SKILL.md）→ ⑤ 本地备份（backups/）→ ⑥ 网络经验搜索 → ⑦ 带着别人的经验分享，允许问用户 |
| **C18** | **3 分钟无动作则自检** | 每 3 分钟无任务执行，主动回顾当前进度，继续主线任务当前节点，不等待指令不陷入空想。 |
| **C19** | **发现违规 → 记录并修复** | 发现违反 C0-C27 约束的事实，立即：① 记入 knowledge-base（fail case 条目）② 修复不合理之处。不问用户，直接执行。 |
| **C20** | **错误范例关键词 ≠ 修改依据** | 错误范例中出现的内容/关键词/代号（如 C11、Keychain 等），不得作为修改任务书约束条件的理由；不得作为修改知识库已有词条的理由；知识库已有词条不得因错误范例而改变其本来表达 |
| **C21** | **修改依据 = 任务主线** | 修改当前内容和行为的唯一依据是任务主线；错误范例不是修改依据，User 主动要求修改也必须以主线为依据 |
| **C22** | **错误范例仅作查询依据** | 错误范例只能作为查询/参考依据，不得作为修改依据；修改当前内容和行为，只有一个依据：任务主线 |
| **C23** | **遇不明则补 → 不违反约束** | 遇到不明白/不理解/不合理，在 C17 查询顺序全部走完后仍无果 → 在不违反现有约束的前提下，将缺失的技能/知识补充到知识库或 Skill；不得通过修改约束条件本身来填补知识缺口 |
| **C24** | **Startup Ritual 强制执行** | 每个 Worker 启动前必须读取历史档案（handoff_log.txt / product_acceptance.json / archive/ 最近 Run 摘要）并写入 logs/startup.txt；未执行者主编 Agent 拒绝验收 |
| **C25** | **角色禁止边界强制** | 任何 Agent 越权操作（Worker 写 EVIDENCE/翻 passes/创建 Git 提交/修改其他环节文件）本身即视为 Fail Case，立即记入 knowledge-base（fail case 条目）并修复，不问用户 |
| **C26** | **证据链硬门槛（HARD GATE）** | 主编 Agent 验收时，缺少任意一项硬门槛字段（VALIDATION_BUNDLE / WORKER_STARTUP_LOG / RESULT / GIT_COMMIT / DIFFSTAT）即视为 FAIL，不得勾选完成 |
| **C27** | **依赖阻断逻辑** | 某环节 MAXED（重试达上限仍失败）时，只阻断依赖它的后续环节，不阻断独立环节；强制向人类报告 blocker 和依赖关系 |

---

## 五、执行约束

### 5.1 任务优先级

```
主线任务 > 分叉任务
```

**强制规则**：
- 分叉任务是主线之外的辅助任务（如调研、安装工具等）
- 分叉任务完成后，必须回到主线任务
- 主线任务未完成时，不应主动发起新的分叉任务

### 5.2 分叉任务定义

| 任务类型 | 说明 |
|---------|------|
| **主线任务** | Skill 开发、测试、集成验证等直接服务于项目目标的任务 |
| **分叉任务** | 调研、安装工具、修复依赖等辅助性任务 |

### 5.3 执行示例

```
❌ 错误：一直停留在分叉任务（安装工具、调研）
✅ 正确：分叉任务完成后 → 回到主线 → 继续主线任务

示例：
1. 用户："安装这个工具" → 分叉任务开始
2. 工具安装完成 → 分叉任务结束
3. 回到主线："继续 Skill 开发" → 主线任务继续
```

---

## 六、参考资料清单

| # | URL | 对应 Skill | 状态 |
|---|-----|-----------|------|
| 1 | github.com/sanshao85/claude-skills-guide | S1/S3/S4 | 待抓取 |
| 2 | doc.biji.com + biji.com/openapi | S1 | 待抓取 |
| 3 | rosetears.cn/archives/85/ | S3/S4/S5 | **已抓取（2026-04-30），已内化到 claude-values v1.1 + supervision-anti-drift v1.1** |
| 4 | rosetears.cn/archives/55/ | S5 | 待抓取 |
| 5 | github.com/JimLiu/baoyu-skills | S2/S3/S6 | 待抓取 |
| 6 | github.com/Fission-AI/OpenSpec/issues/630 | S5 | 待抓取 |
| **R7** | rosetears.cn/archives/85/（完整框架） | **S3/S4/S5** | **制度性防跑偏框架核心来源，含完整 Supervisor-Worker 实践配置** |

### Supervisor-Worker 架构映射表

| 博文 rosetears-85 组件 | 有声漫画流水线对应 |
|----------------------|------------------|
| Claude Code (Supervisor) | 主编 Agent |
| Codex (Worker) | 各环节执行 Agent（脚本/分镜/生图/配音/合成 Agent） |
| tasks.md | production_pipeline.md（过程账本） |
| feature_list.json | product_acceptance.json（结果账本） |
| progress.txt | handoff_log.txt（交接日志） |
| auto_test_openspec/ | archive/（证据仓库） |
| run-<run#>-task-<id>-ref-<ref>-<ts>/ | 环节产出不可变目录 |
| BUNDLE 行 | 各环节交付包指针 |
| EVIDENCE 行 | 主编 Agent 验收结论 |
| HARD GATE | 主编 Agent 的 7 项验收硬门槛 |
| codex exec | 主编 Agent 调用执行 Agent |
| Startup Ritual | 主编 Agent 在各环节前的历史档案读取要求 |

### GitHub 可用 Skills
| # | 仓库 | ⭐ | 对应 |
|---|------|---|------|
| G1 | Astro-Han/karpathy-llm-wiki | 605 | S1 |
| G2 | eugeniughelbur/obsidian-second-brain | 271 | S1/S6 |
| G3 | JimLiu/baoyu-skills | 16,273 | S2/S3/S6 |

---

## 八、每周任务（Weekly Review）

每周一次，审视：
1. 主线目标理解更新
2. Skill 架构合理性
3. 执行进度
4. 主动优化不合理之处
5. 核心记忆更新
6. **Startup Ritual 执行情况**（logs/startup.txt 覆盖率）
7. **两层账本对齐情况**（production_pipeline.md 进度 vs product_acceptance.json passes 状态）
8. **角色越权记录**（Fail Case 中是否有 Agent 越权）
9. **HARD GATE 遵守情况**（EVIDENCE 字段完整性）

---

## 版本历史

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-04-24 | v0.6 | 初始化任务书 |
| 2026-04-30 | **v0.7** | **内化 rosetears.cn/archives/85/ 制度性防跑偏框架；新增 Stage 0 预提取；新增关键词（证据链优先/职责正交化/Startup Ritual）；S3 增加 Supervisor-Worker 架构说明；S4 更新核心能力描述；新增约束 C24-C27；新增 Supervisor-Worker 架构映射表；每周任务增加制度性框架审视项** |
