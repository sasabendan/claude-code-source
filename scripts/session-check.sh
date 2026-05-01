#!/bin/bash
# session-check.sh - /clear 后自动检查主线项目 + 所有 skills 可用性
# 调用方式：每次会话启动时由 CLAUDE.md startup 阶段调用
# 输出：追加写入 tasks/audio-comic-skills/session-check.log

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="$PROJECT_ROOT/tasks/audio-comic-skills/session-check.log"
SKILLS_DIR="$PROJECT_ROOT/skills"
NOW=$(date "+%Y-%m-%d %H:%M:%S")

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

count_scripts() {
    # 用 find 计算文件数（避开 ls/grep 编码问题）
    find "$1" -maxdepth 1 -not -name ".*" -type f 2>/dev/null | wc -l | tr -d ' '
}

write_log() {
    printf '%s\n' "$1" >> "$LOG_FILE"
}

write_log "═══════════════════════════════════════"
write_log "[$NOW] SESSION CHECK"
write_log "WORKDIR: $PROJECT_ROOT"
write_log ""

# ── 1. 主线项目状态 ──────────────────────────────
printf "== 1. Main Project Status ==\n"
write_log "== 1. Main Project Status =="

PROJ_FILES=(
    "tasks/audio-comic-skills/TASK_PROGRESS.md"
    "tasks/audio-comic-skills/heartbeat-state.md"
    "tasks/audio-comic-skills/TASK_REQUIREMENTS.md"
    "tasks/audio-comic-skills/CLAUDE.md"
    "tasks/audio-comic-skills/master-plan.md"
)

PROJ_OK=0; PROJ_TOTAL=0
for f in "${PROJ_FILES[@]}"; do
    ((PROJ_TOTAL++))
    if [ -f "$PROJECT_ROOT/$f" ]; then
        printf "  [OK] %s\n" "$(basename "$f")"
        ((PROJ_OK++))
    else
        printf "  [MISSING] %s\n" "$(basename "$f")"
    fi
done

if [ -f "$PROJECT_ROOT/tasks/audio-comic-skills/heartbeat-state.md" ]; then
    MAIN_TASK=$(grep "^current_main_task:" "$PROJECT_ROOT/tasks/audio-comic-skills/heartbeat-state.md" 2>/dev/null | sed 's/^current_main_task: //' || echo "(unset)")
    LAST_HB=$(grep "^last_heartbeat_at:" "$PROJECT_ROOT/tasks/audio-comic-skills/heartbeat-state.md" 2>/dev/null | sed 's/^last_heartbeat_at: //' || echo "(unknown)")
    printf "  -> Main task: %s\n" "$MAIN_TASK"
    printf "  -> Last heartbeat: %s\n" "$LAST_HB"
    write_log "Main task: $MAIN_TASK"
fi
printf "  Project files: %d/%d [OK]\n" "$PROJ_OK" "$PROJ_TOTAL"
write_log "Project files: $PROJ_OK/$PROJ_TOTAL OK"

# ── 2. 知识库完整性 ──────────────────────────────
printf "\n== 2. Knowledge Base ==\n"
write_log ""
write_log "== 2. Knowledge Base =="

KB_INDEX="$PROJECT_ROOT/tasks/audio-comic-skills/knowledge-base/.index.jsonl"
if [ -f "$KB_INDEX" ]; then
    KB_COUNT=$(grep -c '"name"' "$KB_INDEX" 2>/dev/null || echo 0)
    printf "  [OK] KB index (%d entries)\n" "$KB_COUNT"
    write_log "KB: OK ($KB_COUNT entries)"
else
    printf "  [MISSING] KB index\n"
    write_log "KB: MISSING"
fi

# ── 3. 核心 Skills S0-S5 ──────────────────────────
printf "\n== 3. Core Skills (S0-S5) ==\n"
write_log ""
write_log "== 3. Core Skills (S0-S5) =="

CORE_SKILLS=(task-book-keeper knowledge-base-manager comic-style-consistency audio-comic-workflow supervision-anti-drift self-optimizing-yield)
CORE_OK=0; CORE_TOTAL=0
for skill in "${CORE_SKILLS[@]}"; do
    ((CORE_TOTAL++))
    MD="$SKILLS_DIR/$skill/SKILL.md"
    SCRIPTS="$SKILLS_DIR/$skill/scripts"
    if [ -f "$MD" ] && [ -d "$SCRIPTS" ]; then
        CNT=$(count_scripts "$SCRIPTS")
        printf "  [OK] S-%s (%s scripts)\n" "$skill" "$CNT"
        ((CORE_OK++))
        write_log "S-$skill: OK ($CNT scripts)"
    else
        printf "  [MISSING] S-%s\n" "$skill"
        write_log "S-$skill: MISSING"
    fi
done
printf "  Core Skills: %d/%d [OK]\n" "$CORE_OK" "$CORE_TOTAL"
write_log "Core Skills: $CORE_OK/$CORE_TOTAL OK"

# ── 4. 全量 Skills ───────────────────────────────
printf "\n== 4. All Skills (23 total) ==\n"
write_log ""
write_log "== 4. All Skills (23 total) =="

ALL_OK=0; ALL_TOTAL=0; MISSING_LIST=""
for skill in $(ls "$SKILLS_DIR" 2>/dev/null | grep -v "^\." | sort); do
    ((ALL_TOTAL++))
    MD="$SKILLS_DIR/$skill/SKILL.md"
    SCRIPTS="$SKILLS_DIR/$skill/scripts"
    if [ -f "$MD" ] && [ -d "$SCRIPTS" ]; then
        CNT=$(count_scripts "$SCRIPTS")
        printf "  [OK] %s (%s scripts)\n" "$skill" "$CNT"
        ((ALL_OK++))
    else
        if [ -f "$MD" ] && [ ! -d "$SCRIPTS" ]; then
            printf "  [INCOMPLETE] %s (no scripts/)\n" "$skill"
            MISSING_LIST="$MISSING_LIST $skill"
            write_log "$skill: INCOMPLETE (no scripts/)"
        else
            printf "  [MISSING] %s\n" "$skill"
            MISSING_LIST="$MISSING_LIST $skill"
            write_log "$skill: MISSING"
        fi
    fi
done
printf "  All Skills: %d/%d [OK]\n" "$ALL_OK" "$ALL_TOTAL"
write_log "All Skills: $ALL_OK/$ALL_TOTAL OK"
[ -n "$MISSING_LIST" ] && printf "  Note: Incomplete/missing:%s\n" "$MISSING_LIST"

# ── 5. 关键脚本可用性 ────────────────────────────
printf "\n== 5. Critical Scripts ==\n"
write_log ""
write_log "== 5. Critical Scripts =="

CRITICAL_SCRIPTS=(
    "skills/task-book-keeper/scripts/backup.sh"
    "skills/knowledge-base-manager/scripts/kb-manager.sh"
    "skills/claude-first-check/scripts/heartbeat-service.sh"
)
SCRIPT_OK=0; SCRIPT_TOTAL=0
for s in "${CRITICAL_SCRIPTS[@]}"; do
    ((SCRIPT_TOTAL++))
    if [ -f "$PROJECT_ROOT/$s" ]; then
        if [ -x "$PROJECT_ROOT/$s" ]; then
            printf "  [OK] %s\n" "$s"
        else
            printf "  [WARN] %s (not executable)\n" "$s"
        fi
        ((SCRIPT_OK++))
    else
        printf "  [MISSING] %s\n" "$s"
    fi
done
printf "  Critical Scripts: %d/%d [OK]\n" "$SCRIPT_OK" "$SCRIPT_TOTAL"
write_log "Critical Scripts: $SCRIPT_OK/$SCRIPT_TOTAL OK"

# ── 6. 备份状态 ──────────────────────────────────
printf "\n== 6. Backup Status ==\n"
write_log ""
write_log "== 6. Backup Status =="

BACKUP_DIR="$PROJECT_ROOT/tasks/audio-comic-skills/backups"
if [ -d "$BACKUP_DIR" ]; then
    LOCAL_COUNT=$(ls -t "$BACKUP_DIR"/backup_c0_local_*.tar.gz 2>/dev/null | wc -l | tr -d ' ')
    LAST_BACKUP=$(ls -t "$BACKUP_DIR"/backup_c0_local_*.tar.gz 2>/dev/null | head -1 2>/dev/null | xargs basename 2>/dev/null || echo "none")
    printf "  Local backups: %s (latest: %s)\n" "$LOCAL_COUNT" "$LAST_BACKUP"
    write_log "Backups: OK ($LOCAL_COUNT local)"
else
    printf "  [MISSING] backup dir\n"
    write_log "Backups: MISSING"
fi

# ── 7. 技术债务状态 ───────────────────────────────
printf "\n== 7. Tech Debt ==\n"
write_log ""
write_log "== 7. Tech Debt =="

C0_CRON=$(crontab -l 2>/dev/null | grep "c0-auto-backup" | head -1 || echo "not set")
printf "  C0 cron: %s\n" "$C0_CRON"
write_log "C0 cron: $C0_CRON"

KB_RUST_DIR="$PROJECT_ROOT/tasks/audio-comic-skills/kb-rust"
RUST_BIN=$(find "$KB_RUST_DIR" -name "kb-rust-v2" -type f 2>/dev/null | head -1 || echo "")
if [ -n "$RUST_BIN" ]; then
    printf "  C1 Rust: OK (kb-rust-v2)\n"
    write_log "C1 Rust: OK"
else
    printf "  C1 Rust: pending build\n"
    write_log "C1 Rust: pending"
fi

if [ -f "$PROJECT_ROOT/tasks/audio-comic-skills/reference-06-openspec-630.md" ]; then
    printf "  C5 OpenSpec: OK (doc exists)\n"
    write_log "C5 OpenSpec: OK"
else
    printf "  C5 OpenSpec: missing doc\n"
    write_log "C5 OpenSpec: missing"
fi

write_log ""
write_log "CHECK COMPLETE"
write_log "──────────────────────────────────────────────────"
printf "\n  [DONE] check logged to: %s\n" "$LOG_FILE"
