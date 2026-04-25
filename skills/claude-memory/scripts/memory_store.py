#!/usr/bin/env python3
"""
memory_store.py - Claude 记忆仓库存储脚本
用法：
  python memory_store.py add --key <key> --value <value> [--tags tag1,tag2]
  python memory_store.py get --key <key>
  python memory_store.py list [--tag <tag>]
  python memory_store.py delete --key <key>
  python memory_store.py search <query>
"""

import json
import os
import sys
import argparse
from datetime import datetime, timezone
from pathlib import Path

MEMORY_FILE = Path.home() / ".claude" / "memory-store.jsonl"

def ensure_file():
    MEMORY_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not MEMORY_FILE.exists():
        MEMORY_FILE.write_text("")

def load_records():
    ensure_file()
    records = []
    for line in MEMORY_FILE.read_text().strip().split("\n"):
        if line.strip():
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError:
                pass
    return records

def save_records(records):
    ensure_file()
    MEMORY_FILE.write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in records) + "\n")

def add_record(key, value, tags=None):
    records = load_records()
    # 检查是否已存在
    for i, r in enumerate(records):
        if r.get("key") == key:
            records[i] = {
                "key": key,
                "value": value,
                "tags": tags or [],
                "updated": datetime.now(timezone.utc).isoformat()
            }
            save_records(records)
            print(f"✅ 更新已有记录: {key}")
            return
    records.append({
        "key": key,
        "value": value,
        "tags": tags or [],
        "created": datetime.now(timezone.utc).isoformat(),
        "updated": datetime.now(timezone.utc).isoformat()
    })
    save_records(records)
    print(f"✅ 新增记录: {key}")

def get_record(key):
    records = load_records()
    for r in records:
        if r.get("key") == key:
            print(r["value"])
            return
    print(f"❌ 未找到记录: {key}", file=sys.stderr)
    sys.exit(1)

def list_records(tag=None):
    records = load_records()
    if not records:
        print("(空)")
        return
    for r in records:
        if tag and tag not in r.get("tags", []):
            continue
        updated = r.get("updated", r.get("created", ""))
        tags_str = f" [{','.join(r['tags'])}]" if r.get("tags") else ""
        print(f"[{r['key']}]{tags_str} ({updated})")

def delete_record(key):
    records = load_records()
    new_records = [r for r in records if r.get("key") != key]
    if len(new_records) == len(records):
        print(f"❌ 未找到记录: {key}", file=sys.stderr)
        sys.exit(1)
    save_records(new_records)
    print(f"✅ 已删除: {key}")

def search_records(query):
    records = load_records()
    for r in records:
        q = query.lower()
        if q in r["key"].lower() or q in r["value"].lower() or any(q in t.lower() for t in r.get("tags", [])):
            tags_str = f" [{','.join(r['tags'])}]" if r.get("tags") else ""
            print(f"[{r['key']}]{tags_str}")
            print(f"  {r['value'][:200]}{'...' if len(r['value']) > 200 else ''}")

# --- 授权管理 ---

AUTH_FILE = Path.home() / ".claude" / "authorized-scope.jsonl"

def ensure_auth_file():
    AUTH_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not AUTH_FILE.exists():
        AUTH_FILE.write_text("")

def load_auth_records():
    ensure_auth_file()
    records = []
    for line in AUTH_FILE.read_text().strip().split("\n"):
        if line.strip():
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError:
                pass
    return records

def save_auth_records(records):
    ensure_auth_file()
    AUTH_FILE.write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in records) + "\n")

def add_auth(scope, note=""):
    records = load_auth_records()
    records.append({
        "date": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "scope": scope,
        "granted_by": "user",
        "expires": "task_complete",
        "note": note
    })
    save_auth_records(records)
    print(f"✅ 授权已记录: {scope}")

def list_auth():
    records = load_auth_records()
    if not records:
        print("(空)")
        return
    for r in records:
        print(f"[{r['date']}] {r['scope']}")
        if r.get("note"):
            print(f"  备注: {r['note']}")

def archive_auth():
    records = load_auth_records()
    if not records:
        print("(无记录可归档)")
        return
    archive_name = f"authorized-scope.{datetime.now(timezone.utc).strftime('%Y-%m-%d')}.archived.jsonl"
    archive_path = AUTH_FILE.parent / archive_name
    archive_path.write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in records) + "\n")
    AUTH_FILE.write_text("")
    print(f"✅ 已归档至 {archive_name}，当前授权记录已清空")

def main():
    parser = argparse.ArgumentParser(description="Claude 记忆仓库")
    sub = parser.add_subparsers(dest="cmd")

    p_add = sub.add_parser("add", help="添加记忆")
    p_add.add_argument("--key", required=True)
    p_add.add_argument("--value", required=True)
    p_add.add_argument("--tags")

    p_get = sub.add_parser("get", help="获取记忆")
    p_get.add_argument("--key", required=True)

    p_list = sub.add_parser("list", help="列出所有记忆")
    p_list.add_argument("--tag")

    p_del = sub.add_parser("delete", help="删除记忆")
    p_del.add_argument("--key", required=True)

    p_search = sub.add_parser("search", help="搜索记忆")
    p_search.add_argument("query")

    p_auth = sub.add_parser("auth", help="授权管理")
    p_auth_sub = p_auth.add_subparsers(dest="auth_cmd")

    p_auth_add = p_auth_sub.add_parser("add", help="记录授权")
    p_auth_add.add_argument("--scope", required=True)
    p_auth_add.add_argument("--note", default="")

    p_auth_list = p_auth_sub.add_parser("list", help="列出授权")

    p_auth_archive = p_auth_sub.add_parser("archive", help="归档授权（任务完成后）")

    args = parser.parse_args()

    if args.cmd == "add":
        tags = args.tags.split(",") if args.tags else None
        add_record(args.key, args.value, tags)
    elif args.cmd == "get":
        get_record(args.key)
    elif args.cmd == "list":
        list_records(args.tag)
    elif args.cmd == "delete":
        delete_record(args.key)
    elif args.cmd == "search":
        search_records(args.search if hasattr(args, 'search') else args.query)
    elif args.cmd == "auth":
        if args.auth_cmd == "add":
            add_auth(args.scope, args.note)
        elif args.auth_cmd == "list":
            list_auth()
        elif args.auth_cmd == "archive":
            archive_auth()
        else:
            p_auth.print_help()
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
