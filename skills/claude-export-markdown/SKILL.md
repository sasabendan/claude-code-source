---
name: claude-export-markdown
description: Export a single Claude assistant reply into a clean Markdown file（导出 Claude 回复为 Markdown）。触发词："导出" / "export this" / "save as markdown" / "dump to .md" / "把这条回复保存为 md" / "把刚才那段完整保存" / "convert reply to .md"。Do NOT use when:, self-contained Markdown file that faithfully preserves headings, lists, code blocks, tables, and inline images as remote links. Use this skill whenever the user wants to save, archive, export, dump, convert, or share one specific Claude response as a .md file — especially when they say things like "export this reply", "save as markdown", "把这条回复导出成 md", "把刚才那段完整保存", "dump to markdown", "convert reply to .md", or provide raw reply text / a session .jsonl file and ask for a Markdown render. The skill keeps images as remote URLs (no local download) and packs everything into one file. Do NOT use this skill for saving short snippets or creating reusable reference IDs (use claude-cite-reference instead), and do NOT use it for exporting an entire multi-turn conversation history.
---

# Claude Export to Markdown

A skill for turning one Claude assistant reply into a single well-formed Markdown file, with all images kept as remote URLs.

## When to use

Trigger this skill when the user wants to:

- Save a specific Claude reply as a `.md` file
- Convert a pasted reply into Markdown that renders the same way it did in the UI
- Extract one message from a Claude Code session file (`.jsonl`) as Markdown
- Produce a single self-contained file (no sidecar images folder)

Look for phrases like: "export this reply", "save as markdown", "导出这条回复", "转成 md", "把刚才那段完整保存", "dump this to .md", "give me markdown of that answer".

## Core behavior

1. **One file, self-contained.** Output is a single `.md`. No image folder, no zip.
2. **Images stay remote.** Every `![alt](url)` or `<img src="url">` keeps its original URL. Never download, rewrite to local paths, or inline as base64.
3. **Preserve structure.** Headings, lists, tables, code fences (with language), blockquotes, bold/italic, and link text all survive round-trip.
4. **Tag the source.** Prepend YAML front matter with `exported_at`, `source` (pasted-text or jsonl), `session_id` / `message_id` if available, and `model` if known.
5. **Warn, don't rewrite.** If images are referenced without URLs, or if the input looks truncated, add a comment block at the bottom listing the issues.

## Input modes

The `scripts/export_reply.py` script accepts three input modes. Pick based on what the user supplies.

### Mode A: raw text / pasted Markdown

User pastes the reply content directly.

```bash
python scripts/export_reply.py --from-text --input reply.txt --output reply.md
# or via stdin
cat reply.txt | python scripts/export_reply.py --from-text --output reply.md
```

### Mode B: Claude Code session .jsonl

User provides a `.jsonl` file plus an optional message selector. Each line in the file is a turn; the script filters for assistant messages and concatenates their content blocks.

```bash
# Export the last assistant message
python scripts/export_reply.py --from-jsonl --input session.jsonl --output reply.md

# Export a specific message by index (1-based among assistant messages)
python scripts/export_reply.py --from-jsonl --input session.jsonl --index 3 --output reply.md

# Export by message UUID if the jsonl has one
python scripts/export_reply.py --from-jsonl --input session.jsonl --message-id abc123 --output reply.md

# List assistant messages with previews (does not write a file)
python scripts/export_reply.py --from-jsonl --input session.jsonl --list
```

### Mode C: direct string argument

For quick one-liners, small snippets, or automation:

```bash
python scripts/export_reply.py --from-text --content "# Heading\n\nSome **content**" --output reply.md
```

## Recommended workflow

When the user asks to export a reply:

1. **Clarify the source if ambiguous.** If the user hasn't told you where the reply lives, ask: pasted text, a `.jsonl` file path, or something else?
2. **If `.jsonl`: list first.** Run `--list` so the user can pick which message to export when there's more than one assistant turn.
3. **Run the export.** Save to `/mnt/user-data/outputs/<name>.md` (or the user's chosen path) so the file can be surfaced via `present_files`.
4. **Report image handling.** After export, mention how many images were preserved as remote links and whether any were flagged.
5. **Offer a preview.** Show the first 30-40 lines of the output in chat so the user can sanity-check formatting.

## Image rules in detail

- Markdown image syntax `![alt](https://...)` is preserved verbatim
- HTML `<img src="https://..." alt="..." />` is preserved verbatim
- If a URL is relative or looks invalid (not `http(s)://` or `data:`), it is left as-is but logged in the trailing comment block
- `data:` URIs are kept inline but also flagged, because they can make the file huge
- No image download ever happens; the skill does not hit the network

## Output format

```markdown
---
exported_at: 2026-04-24T17:05:00Z
source: jsonl
session_file: session.jsonl
message_id: abc123
model: claude-opus-4-7
image_count: 3
---

# Original reply content starts here

... preserved verbatim ...

<!-- export notes
- 3 image links preserved as remote URLs
- no issues detected
-->
```

## CLI quick reference

| Action | Command |
|---|---|
| Pasted text -> md | `python scripts/export_reply.py --from-text --input reply.txt --output out.md` |
| Inline string -> md | `python scripts/export_reply.py --from-text --content "..." --output out.md` |
| Last assistant turn in jsonl | `python scripts/export_reply.py --from-jsonl --input s.jsonl --output out.md` |
| Nth assistant turn | `python scripts/export_reply.py --from-jsonl --input s.jsonl --index 2 --output out.md` |
| List jsonl turns | `python scripts/export_reply.py --from-jsonl --input s.jsonl --list` |

## What this skill does NOT do

- Does not download images or embed them as base64 (by design, to keep files small and URLs canonical)
- Does not export multi-turn conversations (only one assistant reply per run)
- Does not convert to HTML, PDF, or other formats (use `pandoc` downstream if needed)
- Does not manage reusable snippet references (see `claude-cite-reference`)

---

## 版本历史

### v1.0 (2026-04-30)
- 补录版本历史规则（约束元数据库建设 #BR-002）
- 嵌入 version-history 约束：版本号只追加不覆盖
