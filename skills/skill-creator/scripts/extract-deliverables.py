#!/usr/bin/env python3
"""
产出物提取脚本：解析 SKILL.md 中的脚本文件引用
用法：python3 extract-deliverables.py <SKILL.md路径>
输出：JSON 数组，每个元素含 path/exists/exec 字段
只匹配文件路径，不匹配命令示例（如 python scripts/cite.py add）
"""
import sys, os, re, json

def extract_deliverables(skill_file):
    skill_dir = os.path.dirname(skill_file)  # e.g., skills/audio-comic-workflow/
    skill_name = os.path.basename(skill_dir)  # e.g., audio-comic-workflow
    
    try:
        content = open(skill_file).read()
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        return

    found = set()
    # 1. 文件路径：反引号/双引号/单引号包裹，以 scripts/ 开头（不含空格/参数）
    for m in re.finditer(r'[\'"`]([^\'"`\n]*?)[\'"`]', content):
        p = m.group(1).strip()
        if not p:
            continue
        if ' ' in p:  # 命令示例有参数，跳过
            continue
        if 'scripts/' not in p:
            continue
        if p.startswith('http'):
            continue
        found.add(p)

    # 2. 代码入口字段
    for m in re.finditer(r'(?:代码入口|script_path|script|实现|入口):\s*([^\n]+)', content):
        for part in m.group(1).split('|'):
            p = part.strip().strip(' "\':;')
            if 'scripts/' in p and not p.startswith('http') and ' ' not in p:
                found.add(p)

    results = []
    seen = set()
    for path in sorted(found):
        if path in seen:
            continue
        seen.add(path)
        
        # 路径解析：如果是 skills/<skill>/scripts/... 形式，去掉重复前缀
        # e.g., "skills/audio-comic-workflow/scripts/..." 在 skills/audio-comic-workflow/SKILL.md 中
        if path.startswith('skills/' + skill_name + '/'):
            # 去掉前辍 scripts/<name>/
            rest = path[len('skills/' + skill_name + '/'):]
            path = rest
        
        full = os.path.normpath(os.path.join(skill_dir, path))
        exists = os.path.exists(full)
        is_file = os.path.isfile(full) if exists else False
        is_exec = os.access(full, os.X_OK) if is_file else False
        results.append({
            "path": path,
            "exists": exists,
            "exec": is_exec
        })

    print(json.dumps(results))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python3 extract-deliverables.py <SKILL.md路径>")
        sys.exit(1)
    extract_deliverables(sys.argv[1])
