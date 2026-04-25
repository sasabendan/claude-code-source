#!/usr/bin/env python3
"""
cite.py — Reference snippet manager for the claude-cite-reference skill.

Storage: JSONL file, one reference per line.
Location resolution:
  1. $CLAUDE_REF_FILE
  2. <git-root>/.claude/refs.jsonl (if inside a git repo)
  3. ./.claude/refs.jsonl (current dir)
  4. ~/.claude/refs.jsonl

Commands:
  add     Add a new reference (content via --stdin or --content)
  list    List references (optionally filter by --tag)
  show    Print one or more references (default: plain; --format block for ref tags)
  delete  Remove a reference by ID
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

ID_PATTERN = re.compile(r"^[a-zA-Z0-9_-]{1,40}$")


def resolve_store_path() -> Path:
    env = os.environ.get("CLAUDE_REF_FILE")
    if env:
        return Path(env).expanduser()

    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True, timeout=2,
        )
        root = Path(result.stdout.strip())
        if root.exists():
            return root / ".claude" / "refs.jsonl"
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        pass

    local = Path.cwd() / ".claude" / "refs.jsonl"
    if local.parent.exists() or (Path.cwd() / ".git").exists():
        return local

    return Path.home() / ".claude" / "refs.jsonl"


def load_all(path: Path) -> list[dict]:
    if not path.exists():
        return []
    entries = []
    with path.open("r", encoding="utf-8") as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            try:
                entries.append(json.loads(line))
            except json.JSONDecodeError as e:
                print(f"warning: skipping malformed line {line_num}: {e}", file=sys.stderr)
    return entries


def write_all(path: Path, entries: Iterable[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w", encoding="utf-8") as f:
        for entry in entries:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    tmp.replace(path)


def slugify(content: str, existing_ids: set[str]) -> str:
    # IDs stay ASCII so they're easy to type on CLI; fall back to a
    # timestamp-based id if the content has no ASCII word chars.
    words = re.findall(r"[A-Za-z0-9]+", content)[:4]
    base = "-".join(w.lower() for w in words)[:30]
    if not base:
        base = "ref-" + datetime.now(timezone.utc).strftime("%m%d-%H%M%S")
    candidate = base
    i = 2
    while candidate in existing_ids:
        candidate = f"{base}-{i}"
        i += 1
    return candidate


def cmd_add(args) -> int:
    path = resolve_store_path()
    entries = load_all(path)
    ids = {e["id"] for e in entries}

    if args.content:
        content = args.content
    elif args.stdin or not sys.stdin.isatty():
        content = sys.stdin.read()
    else:
        print("error: provide content via --content or --stdin", file=sys.stderr)
        return 1

    content = content.strip()
    if not content:
        print("error: empty content", file=sys.stderr)
        return 1

    ref_id = args.id or slugify(content, ids)
    if not ID_PATTERN.match(ref_id):
        print(f"error: id '{ref_id}' must match {ID_PATTERN.pattern}", file=sys.stderr)
        return 1

    if ref_id in ids and not args.force:
        existing = next(e for e in entries if e["id"] == ref_id)
        print(f"error: id '{ref_id}' already exists (created {existing['created']}).", file=sys.stderr)
        print("Use --force to overwrite or pick a different --id.", file=sys.stderr)
        return 2

    tags = [t.strip() for t in (args.tags or "").split(",") if t.strip()]
    new_entry = {
        "id": ref_id,
        "created": datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"),
        "source": args.source,
        "tags": tags,
        "content": content,
    }

    if ref_id in ids:
        entries = [e for e in entries if e["id"] != ref_id]
    entries.append(new_entry)
    write_all(path, entries)

    print(f"saved: @ref:{ref_id}  ({len(content)} chars)  -> {path}")
    return 0


def cmd_list(args) -> int:
    path = resolve_store_path()
    entries = load_all(path)

    if args.tag:
        entries = [e for e in entries if args.tag in (e.get("tags") or [])]

    if not entries:
        print(f"(no references in {path})")
        return 0

    if args.format == "json":
        print(json.dumps(entries, ensure_ascii=False, indent=2))
        return 0

    for e in entries:
        content = e.get("content", "")
        if args.format == "short":
            preview = content.replace("\n", " ")[:60]
            tag_str = f"  [{','.join(e.get('tags') or [])}]" if e.get("tags") else ""
            print(f"  @ref:{e['id']:<20} {preview}{tag_str}")
        else:
            tag_str = f"  tags: {','.join(e.get('tags') or [])}" if e.get("tags") else ""
            print(f"@ref:{e['id']}  ({e['created']}){tag_str}")
            print("  " + content.replace("\n", "\n  ")[:400])
            if len(content) > 400:
                print(f"  ... ({len(content) - 400} more chars)")
            print()
    return 0


def cmd_show(args) -> int:
    path = resolve_store_path()
    entries = {e["id"]: e for e in load_all(path)}

    missing = [i for i in args.ids if i not in entries]
    if missing:
        print(f"error: missing ref id(s): {', '.join(missing)}", file=sys.stderr)
        return 3

    for i, ref_id in enumerate(args.ids):
        e = entries[ref_id]
        if args.format == "block":
            tag_attr = f' tags="{",".join(e.get("tags") or [])}"' if e.get("tags") else ""
            print(f'<ref id="{e["id"]}" created="{e["created"]}"{tag_attr}>')
            print(e["content"])
            print("</ref>")
            if i < len(args.ids) - 1:
                print()
        elif args.format == "json":
            print(json.dumps(e, ensure_ascii=False))
        else:
            print(e["content"])
            if i < len(args.ids) - 1:
                print()
    return 0


def cmd_delete(args) -> int:
    path = resolve_store_path()
    entries = load_all(path)
    before = len(entries)
    entries = [e for e in entries if e["id"] != args.id]
    if len(entries) == before:
        print(f"error: no ref with id '{args.id}'", file=sys.stderr)
        return 3
    write_all(path, entries)
    print(f"deleted: @ref:{args.id}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="cite", description=__doc__.splitlines()[1])
    sub = p.add_subparsers(dest="cmd", required=True)

    pa = sub.add_parser("add", help="Add a reference")
    pa.add_argument("--id", help="Reference ID (auto-generated if omitted)")
    pa.add_argument("--tags", help="Comma-separated tags")
    pa.add_argument("--source", default="assistant", help="Source label (default: assistant)")
    pa.add_argument("--content", help="Inline content (else read from stdin)")
    pa.add_argument("--stdin", action="store_true", help="Read content from stdin")
    pa.add_argument("--force", action="store_true", help="Overwrite existing ID")
    pa.set_defaults(func=cmd_add)

    pl = sub.add_parser("list", help="List references")
    pl.add_argument("--tag", help="Filter by tag")
    pl.add_argument("--format", choices=["full", "short", "json"], default="full")
    pl.set_defaults(func=cmd_list)

    ps = sub.add_parser("show", help="Show one or more references")
    ps.add_argument("ids", nargs="+", help="Reference IDs to show")
    ps.add_argument("--format", choices=["plain", "block", "json"], default="plain")
    ps.set_defaults(func=cmd_show)

    pd = sub.add_parser("delete", help="Delete a reference")
    pd.add_argument("id", help="Reference ID")
    pd.set_defaults(func=cmd_delete)

    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
