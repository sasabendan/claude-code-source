#!/usr/bin/env python3
"""
export_reply.py — Export one Claude assistant reply into a single Markdown file.

Supports two input sources:
  --from-text   Raw Markdown text (via --input <file>, --content <str>, or stdin)
  --from-jsonl  Claude Code session .jsonl (pick with --index, --message-id, or default = last)

Images are always kept as remote URLs. No downloads happen. Issues (bad URLs,
data: URIs, truncated input) are collected into a trailing HTML-comment block.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

MD_IMAGE_RE = re.compile(r"!\[([^\]]*)\]\(([^)]+)\)")
HTML_IMAGE_RE = re.compile(r'<img\s+[^>]*src=["\']([^"\']+)["\'][^>]*>', re.IGNORECASE)


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


# ---------------------------------------------------------------------------
# JSONL parsing
# ---------------------------------------------------------------------------

def extract_assistant_turns(jsonl_path: Path) -> list[dict]:
    """Return a list of normalized assistant turns.

    Handles two common shapes:
      1. Claude Code native: {"type": "assistant", "message": {"content": [...]}}
      2. API-style:          {"role": "assistant", "content": [...] or "..."}
    """
    turns = []
    with jsonl_path.open("r", encoding="utf-8") as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue

            # Shape 1: Claude Code native
            if obj.get("type") == "assistant" and isinstance(obj.get("message"), dict):
                msg = obj["message"]
                content = msg.get("content", [])
                turns.append({
                    "line": line_num,
                    "role": "assistant",
                    "content": content,
                    "message_id": msg.get("id") or obj.get("uuid"),
                    "model": msg.get("model"),
                    "timestamp": obj.get("timestamp"),
                })
                continue

            # Shape 2: API-style
            if obj.get("role") == "assistant":
                turns.append({
                    "line": line_num,
                    "role": "assistant",
                    "content": obj.get("content", ""),
                    "message_id": obj.get("id"),
                    "model": obj.get("model"),
                    "timestamp": obj.get("timestamp"),
                })
    return turns


def content_to_markdown(content: Any) -> str:
    """Flatten API-style content blocks into Markdown text.

    Strings pass through. Block lists keep only text blocks (tool_use,
    tool_result, thinking are dropped — they aren't part of the user-visible
    reply).
    """
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for block in content:
            if not isinstance(block, dict):
                continue
            btype = block.get("type")
            if btype == "text":
                parts.append(block.get("text", ""))
            # intentionally skip: tool_use, tool_result, thinking, image payloads
        return "\n\n".join(p for p in parts if p)
    return str(content)


def preview(text: str, width: int = 70) -> str:
    first = text.strip().splitlines()[0] if text.strip() else ""
    first = re.sub(r"\s+", " ", first)
    return first[:width] + ("..." if len(first) > width else "")


# ---------------------------------------------------------------------------
# Image auditing
# ---------------------------------------------------------------------------

def audit_images(markdown: str) -> tuple[int, list[str]]:
    """Count images and collect warnings about them."""
    urls = []
    urls.extend(url for _, url in MD_IMAGE_RE.findall(markdown))
    urls.extend(HTML_IMAGE_RE.findall(markdown))

    warnings = []
    for url in urls:
        if url.startswith("data:"):
            warnings.append(f"data: URI kept inline (may be large): {url[:40]}...")
        elif not url.startswith(("http://", "https://")):
            warnings.append(f"non-http image reference kept as-is: {url}")

    return len(urls), warnings


# ---------------------------------------------------------------------------
# Output assembly
# ---------------------------------------------------------------------------

def build_output(
    body: str,
    source: str,
    extra_front_matter: dict | None = None,
) -> str:
    image_count, warnings = audit_images(body)

    front = {
        "exported_at": now_iso(),
        "source": source,
        "image_count": image_count,
    }
    if extra_front_matter:
        front.update({k: v for k, v in extra_front_matter.items() if v is not None})

    lines = ["---"]
    for k, v in front.items():
        if isinstance(v, str) and (":" in v or v.startswith(("'", '"'))):
            v = json.dumps(v, ensure_ascii=False)
        lines.append(f"{k}: {v}")
    lines.append("---")
    lines.append("")
    lines.append(body.rstrip())
    lines.append("")

    if warnings or image_count:
        lines.append("")
        lines.append("<!-- export notes")
        if image_count:
            lines.append(f"- {image_count} image reference(s) preserved as remote links")
        for w in warnings:
            lines.append(f"- WARN: {w}")
        if not warnings:
            lines.append("- no issues detected")
        lines.append("-->")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Input resolution
# ---------------------------------------------------------------------------

def read_text_input(args) -> str:
    if args.content is not None:
        # allow literal \n in the CLI argument
        return args.content
    if args.input:
        return Path(args.input).read_text(encoding="utf-8")
    if not sys.stdin.isatty():
        return sys.stdin.read()
    print("error: provide --input <file>, --content <str>, or pipe via stdin", file=sys.stderr)
    sys.exit(1)


def resolve_jsonl_turn(turns: list[dict], args) -> dict:
    if not turns:
        print("error: no assistant turns found in jsonl", file=sys.stderr)
        sys.exit(1)

    if args.message_id:
        for t in turns:
            if t.get("message_id") == args.message_id:
                return t
        print(f"error: message-id '{args.message_id}' not found", file=sys.stderr)
        sys.exit(1)

    if args.index is not None:
        if args.index < 1 or args.index > len(turns):
            print(f"error: --index {args.index} out of range (1..{len(turns)})", file=sys.stderr)
            sys.exit(1)
        return turns[args.index - 1]

    return turns[-1]


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[1])

    mode = p.add_mutually_exclusive_group(required=True)
    mode.add_argument("--from-text", action="store_true", help="Input is raw Markdown text")
    mode.add_argument("--from-jsonl", action="store_true", help="Input is a Claude Code session .jsonl")

    p.add_argument("--input", help="Input file path")
    p.add_argument("--content", help="Inline content string (text mode only)")
    p.add_argument("--output", "-o", help="Output .md path (required unless --list)")

    # jsonl-specific
    p.add_argument("--index", type=int, help="1-based index among assistant turns (jsonl mode)")
    p.add_argument("--message-id", help="Exact message id to export (jsonl mode)")
    p.add_argument("--list", action="store_true", help="List assistant turns from jsonl and exit")

    args = p.parse_args(argv)

    if args.from_text:
        body = read_text_input(args)
        if not args.output:
            print("error: --output is required for text mode", file=sys.stderr)
            return 1
        output_md = build_output(body, source="pasted-text")

    else:  # from-jsonl
        if not args.input:
            print("error: --input <session.jsonl> is required", file=sys.stderr)
            return 1
        jsonl_path = Path(args.input)
        if not jsonl_path.exists():
            print(f"error: {jsonl_path} not found", file=sys.stderr)
            return 1

        turns = extract_assistant_turns(jsonl_path)

        if args.list:
            if not turns:
                print("(no assistant turns found)")
                return 0
            print(f"found {len(turns)} assistant turn(s) in {jsonl_path}:")
            for i, t in enumerate(turns, 1):
                body = content_to_markdown(t["content"])
                print(f"  [{i}] line {t['line']}  id={t.get('message_id') or '-'}  {preview(body)}")
            return 0

        if not args.output:
            print("error: --output is required unless --list", file=sys.stderr)
            return 1

        turn = resolve_jsonl_turn(turns, args)
        body = content_to_markdown(turn["content"])
        output_md = build_output(
            body,
            source="jsonl",
            extra_front_matter={
                "session_file": jsonl_path.name,
                "message_id": turn.get("message_id"),
                "model": turn.get("model"),
            },
        )

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(output_md, encoding="utf-8")

    image_count, warnings = audit_images(output_md)
    print(f"wrote: {out_path}  ({len(output_md)} chars, {image_count} image ref(s))")
    for w in warnings:
        print(f"  WARN: {w}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
