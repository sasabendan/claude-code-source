#!/usr/bin/env python3
"""
kb-auto-linker: 知识库自动化双链关联脚本
对每个孤立页面，分析内容 → 找相关已有页面 → 添加 [[wikilinks]]
"""
import json, os, re, sys
from pathlib import Path

KB_DIR = Path("knowledge-base")
INDEX_FILE = KB_DIR / ".index.jsonl"
BACKLINKS_FILE = KB_DIR / "_backlinks.json"

# 关联策略表
STRATEGY = {
    "kb-rust": ["kb-rust 归档迁移记录", "knowledge-base-manager", "kb-rust v2"],
    "v1": ["kb-rust 归档迁移记录", "knowledge-base-manager"],
    "v2": ["kb-rust v2", "knowledge-base-manager"],
    "reference": ["audio-comic-workflow", "knowledge-base-manager"],
    "nca": ["supervision-anti-drift", "self-optimizing-yield"],
    "pipeline": ["audio-comic-workflow"],
    "漂移": ["supervision-anti-drift"],
    "良品率": ["self-optimizing-yield", "comic-style-consistency"],
    "画风": ["comic-style-consistency"],
    "角色": ["comic-style-consistency"],
    "skill-creator": ["audio-comic-workflow"],
    "rosetears": ["supervision-anti-drift", "audio-comic-workflow"],
    "baoyu": ["audio-comic-workflow"],
    "naruto": ["audio-comic-workflow"],
    "download": ["knowledge-base-manager"],  # 下载文件先判定
    "claude skills": ["audio-comic-workflow"],
    "supervisor": ["supervision-anti-drift"],
    "opensepc": ["supervision-anti-drift"],
}

def load_index():
    entries = {}
    with open(INDEX_FILE) as f:
        for line in f:
            try:
                e = json.loads(line.strip())
                name = e.get("name", "")
                file = e.get("file", "")
                if name and file:
                    entries[name] = file
            except:
                pass
    return entries

def load_backlinks():
    with open(BACKLINKS_FILE) as f:
        return json.load(f)

def find_orphans(entries, backlinks):
    targets = set(backlinks.keys())
    return entries - targets

def get_page_path(name, entries):
    """从 name 找到文件路径"""
    # 直接匹配
    if name in entries:
        return KB_DIR / entries[name]
    # 模糊匹配
    for key, path in entries.items():
        if name.lower() in key.lower() or key.lower() in name.lower():
            return KB_DIR / path
    return None

def find_links(page_name, content, entries):
    """找内容相关的已有页面链接"""
    candidates = []
    content_lower = content.lower()
    
    for kw, targets in STRATEGY.items():
        if kw in content_lower:
            for t in targets:
                if t != page_name and t not in candidates:
                    candidates.append(t)
    
    # 也搜 KB 索引
    index = load_index()
    for name, file in index.items():
        if name == page_name or name in candidates:
            continue
        # 简单关键词重叠检测
        name_lower = name.lower()
        if any(k in name_lower or name_lower in k for k in content_lower.split()):
            if name not in candidates:
                candidates.append(name)
    
    return candidates[:3]  # 最多 3 个

def add_links(page_name, links, entries):
    """在页面末尾添加 wikilinks"""
    path = get_page_path(page_name, entries)
    if not path or not path.exists():
        return False, f"文件不存在: {path}"
    
    content = path.read_text()
    
    # 检查是否已有链接
    for link in links:
        if f"[[{link}]]" in content:
            links = [l for l in links if l != link]
    
    if not links:
        return False, "所有链接已存在"
    
    # 添加到末尾
    new_section = "\n\n## 相关链接\n" + "\n".join(f"- [[{l}]]" for l in links)
    
    if "## 相关链接" in content:
        return False, "已有相关链接节"
    
    path.write_text(content.rstrip() + new_section + "\n")
    return True, f"添加: {', '.join(links)}"

def main():
    print("=" * 50)
    print("kb-auto-linker: 知识库双链自动化关联")
    print("=" * 50)
    
    entries = load_index()
    backlinks = load_backlinks()
    orphans = find_orphans(entries, backlinks)
    
    print(f"\n孤立页面数: {len(orphans)}")
    
    added = []
    skipped = []
    
    for page in sorted(orphans):
        path = get_page_path(page, entries)
        if not path or not path.exists():
            skipped.append({"page": page, "reason": "文件路径不存在"})
            continue
        
        try:
            content = path.read_text(encoding="utf-8")
        except:
            skipped.append({"page": page, "reason": "文件读取失败"})
            continue
        
        links = find_links(page, content, entries)
        
        if not links:
            skipped.append({"page": page, "reason": "无相关目标页面"})
            continue
        
        ok, msg = add_links(page, links, entries)
        if ok:
            added.append({"from": page, "to": links, "reason": msg})
            print(f"  ✅ {page} → {', '.join(links)}")
        else:
            skipped.append({"page": page, "reason": msg})
    
    print(f"\n结果:")
    print(f"  添加链接: {len(added)} 个页面")
    print(f"  跳过: {len(skipped)} 个页面")
    
    if added:
        print("\n建议运行:")
        print("  kb-rust-v2 rebuild --kb-dir knowledge-base")
        print("  kb-rust-v2 lint --kb-dir knowledge-base")
    
    return {"orphans_before": len(orphans), "added": added, "skipped": skipped}

if __name__ == "__main__":
    os.chdir("/Users/jennyhu/claude-code-source/tasks/audio-comic-skills")
    result = main()
    print(f"\n{json.dumps(result, ensure_ascii=False, indent=2)}")
