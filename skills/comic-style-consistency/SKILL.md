---
name: comic-style-consistency
description: 解决 AI 生图和配音的风格漂移问题。当用户说"生成角色"、"保持画风"、"统一配音风格"、"风格锚定"时触发。核心能力包括角色/场景/画风锚定（LoRA 或 reference image 池），声音一致性（固定音色 ID + 情感参数模板）。支持本地和云端两种模式。
---

# Skill: comic-style-consistency（风格一致性）

## 功能定位
确保 AI 生成画面和声音的风格一致性，解决风格漂移问题。

## 核心能力

| 能力 | 说明 | 类型 |
|------|------|------|
| 画风锚定 | LoRA 或 reference image 池 | [本地请求] |
| 角色一致性 | 固定角色特征参数 | [本地请求] |
| 声音一致 | 固定音色 ID + 情感模板 | [网络请求]/[本地请求] |
| 风格校验 | 生成后一致性检查 | [本地请求] |

## 输入

```yaml
action: generate|anchor|verify|voice
entity: character|scene|style|voice
content: <内容>
style_id: <风格 ID，可选>
voice_id: <音色 ID，可选>
```

## 输出

```yaml
status: success
style_params: <风格参数>
consistency_score: <一致性分数 0-1>
artifacts: <生成的文件路径>
```

## 触发场景

| 场景 | 示例 |
|------|------|
| 生成角色 | "生成主角形象" / "创建新角色" |
| 保持画风 | "保持之前的风格" / "风格统一" |
| 统一配音 | "统一角色声音" / "配音风格一致" |

## 风格锚定机制

```
Reference Image Pool
    ├── character_refs/
    │   ├── protagonist_001.png
    │   └── antagonist_001.png
    ├── scene_refs/
    │   └── common_scenes/
    └── style_refs/
        └── color_palette.json

LoRA Models
    ├── character_lora/
    └── style_lora/
```

## 声音一致性方案

```
Voice Profile
    ├── voice_id: <固定 ID>
    ├── emotion_template: <情感参数>
    │   ├── happy: [0.8, 0.9, 1.0]
    │   ├── sad: [0.3, 0.5, 0.7]
    │   └── angry: [0.9, 0.7, 0.6]
    └── settings: <音色设置>
```

## 一致性校验

```python
consistency_score = compare(
    generated_image, 
    reference_pool,
    threshold=0.85  # NCA 必要条件
)
```

## 参考资料

- JimLiu/baoyu-skills（风格锚定方案）
- eugeniughelbur/obsidian-second-brain（自我优化）

## 验收标准

- [ ] 风格锚定参数可配置
- [ ] 声音一致性可校验
- [ ] 一致性分数 ≥ 0.85
- [ ] 风格参数持久化

## 代码入口

`skills/comic-style-consistency/scripts/style-manager.sh`
