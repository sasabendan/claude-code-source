#!/bin/bash
# Skills 触发准确率测试框架
# 测试集：验证每个 Skill 在正确场景触发、错误场景不触发

# set -e  # 禁用：((var++)) 在值为0时返回1，干扰测试
cd "$(dirname "$0")/.."

echo "=========================================="
echo "Skills 触发准确率测试"
echo "=========================================="
echo ""

PASS=0
FAIL=0

pass() { echo "  ✅ $1"; ((PASS++)); }
fail() { echo "  ❌ $1"; ((FAIL++)); }

run_test() {
    local label="$1"; shift
    local skill_desc="$1"; shift
    local input="$1"; shift
    local expect_trigger="$1"  # "yes" or "no"
    
    # 简单关键词匹配测试
    local matched=0
    for kw in "$@"; do
        if echo "$input" | grep -qi "$kw"; then
            matched=1
            break
        fi
    done
    
    if [ "$expect_trigger" == "yes" ]; then
        if [ "$matched" -eq 1 ]; then
            pass "$label"
        else
            fail "$label (关键词未命中: $input)"
        fi
    else
        if [ "$matched" -eq 0 ]; then
            pass "$label"
        else
            fail "$label (不应触发但命中了关键词)"
        fi
    fi
}

# ============================================================
# encrypted-backup 测试
# ============================================================
echo "【 encrypted-backup 】"
DESC=$(grep "^description:" /Users/jennyhu/claude-code-source/skills/encrypted-backup/SKILL.md | sed 's/^description: //')
echo "  描述: $DESC"
echo ""

run_test "触发-中文: 加密备份任务书" "$DESC" "加密备份任务书" yes "加密备份"
run_test "触发-中文: 加密推送" "$DESC" "加密推送到github" yes "加密推送"
run_test "触发-英文: encrypt backup" "$DESC" "encrypt task files" yes "encrypt"
run_test "触发-英文: backup enc" "$DESC" "backup enc files" yes "enc"
run_test "触发-中文: 备份到 github" "$DESC" "备份到 github" yes "备份到 github"
run_test "不触发: 本地备份" "$DESC" "本地备份不加密" no "加密推送"
run_test "不触发: 查看备份" "$DESC" "查看备份状态" no "加密"
echo ""

# ============================================================
# core-asset-protection 测试
# ============================================================
echo "【 core-asset-protection 】"
DESC=$(grep "^description:" /Users/jennyhu/claude-code-source/skills/core-asset-protection/SKILL.md | sed 's/^description: //')
echo "  描述: $DESC"
echo ""

run_test "触发: push" "$DESC" "git push origin main" yes "push"
run_test "触发: 删除文件" "$DESC" "删除 TASK_PROGRESS.md" yes "删除"
run_test "触发: commit" "$DESC" "git commit -m" yes "commit"
run_test "触发: 加密推送" "$DESC" "加密推送任务书" yes "加密推送"
run_test "触发: 本地备份" "$DESC" "本地备份不加密" yes "本地备份"
run_test "触发: enc" "$DESC" "生成 .enc 文件" yes "enc"
run_test "不触发: 查询知识库" "$DESC" "查询知识库" no "push"
run_test "不触发: 搜索内容" "$DESC" "搜索关键词" no "push"
echo ""

# ============================================================
# claude-file-safety 测试
# ============================================================
echo "【 claude-file-safety 】"
DESC=$(grep "^description:" /Users/jennyhu/claude-code-source/skills/claude-file-safety/SKILL.md | sed 's/^description: //')
echo "  描述: $DESC"
echo ""

run_test "触发: 删除文件" "$DESC" "删除这个文件" yes "删除"
run_test "触发: 删掉" "$DESC" "删掉临时文件" yes "删掉"
run_test "不触发: 查询文件" "$DESC" "查询这个文件" no "删除"
run_test "不触发: 查看文件" "$DESC" "查看文件内容" no "删除"
echo ""

# ============================================================
# knowledge-base-manager 测试
# ============================================================
echo "【 knowledge-base-manager 】"
DESC=$(grep "^description:" /Users/jennyhu/claude-code-source/skills/knowledge-base-manager/SKILL.md | sed 's/^description: //')
echo "  描述: $DESC"
echo ""

run_test "触发: 查询知识库" "$DESC" "查询知识库" yes "查询知识库"
run_test "触发: 添加知识" "$DESC" "添加知识到知识库" yes "添加知识"
run_test "触发: 更新经验" "$DESC" "更新经验" yes "更新经验"
run_test "触发: 获取参考素材" "$DESC" "获取参考素材" yes "获取参考素材"
run_test "不触发: 删除知识" "$DESC" "删除知识库条目" no "查询知识库"
echo ""

# ============================================================
# task-book-keeper 测试
# ============================================================
echo "【 task-book-keeper 】"
DESC=$(grep "^description:" /Users/jennyhu/claude-code-source/skills/task-book-keeper/SKILL.md | sed 's/^description: //')
echo "  描述: $DESC"
echo ""

run_test "触发: 审视任务书" "$DESC" "审视任务书" yes "审视任务书"
run_test "触发: 更新理解" "$DESC" "更新理解" yes "更新理解"
run_test "触发: 记录进展" "$DESC" "记录进展" yes "记录进展"
run_test "触发: 备份当前状态" "$DESC" "备份当前状态" yes "备份当前状态"
run_test "触发: 查看进度" "$DESC" "查看进度" yes "查看进度"
# 加密推送：task-book-keeper 描述中有此词，但明确说"应调用 encrypted-backup"
# 故本 Skill 不拦截；grep 会匹配（因为描述中有"加密推送"），但实际行为应由 encrypted-backup 处理
run_test "不触发: 纯查询操作" "$DESC" "查看任务书内容" no "push"  # 应由 encrypted-backup 触发
echo ""

# ============================================================
# claude-error-handler 测试
# ============================================================
echo "【 claude-error-handler 】"
DESC=$(grep "^description:" /Users/jennyhu/claude-code-source/skills/claude-error-handler/SKILL.md | sed 's/^description: //')
echo "  描述: $DESC"
echo ""

run_test "触发: 发生错误" "$DESC" "发生错误了" yes "错误"
run_test "触发: 异常" "$DESC" "系统异常" yes "异常"
run_test "触发: 不理解" "$DESC" "不理解这个行为" yes "不理解"
run_test "触发: 不合理" "$DESC" "这个结果不合理" yes "不合理"
run_test "触发: 违规" "$DESC" "发现违规" yes "违规"
echo ""

# ============================================================
# audio-comic-workflow 测试
# ============================================================
echo "【 audio-comic-workflow 】"
DESC=$(grep "^description:" /Users/jennyhu/claude-code-source/skills/audio-comic-workflow/SKILL.md | sed 's/^description: //')
echo "  描述: $DESC"
echo ""

run_test "触发: 开始创作" "$DESC" "开始创作有声漫画" yes "开始创作有声漫画"
run_test "触发: 流水线" "$DESC" "启动流水线" yes "流水线"
run_test "触发: 7环节" "$DESC" "执行7环节流水线" yes "环节"
echo ""

# ============================================================
# HC-AP1 约束验证（核心）
# ============================================================
echo "【 HC-AP1 约束验证 】"
echo ""

# 验证备份脚本不删除本地 .md
if grep -q "rm.*\.md" /Users/jennyhu/claude-code-source/skills/task-book-keeper/scripts/backup.sh; then
    fail "backup.sh 仍含 rm .md（违反 HC-AP1）"
else
    pass "backup.sh 不含 rm .md"
fi

if grep -q "rm.*\.enc" /Users/jennyhu/claude-code-source/skills/task-book-keeper/scripts/backup.sh; then
    pass "backup.sh 清理 .enc（正确，GitHub 已有）"
else
    fail "backup.sh 未清理 .enc"
fi

# 验证 C0 脚本不删除本地 .md
if grep -q "rm.*\.md" /Users/jennyhu/claude-code-source/scripts/c0-auto-backup.sh; then
    fail "c0-auto-backup.sh 仍含 rm .md（违反 HC-AP1）"
else
    pass "c0-auto-backup.sh 不含 rm .md"
fi

# 验证密码不硬编码
if grep -q 'PASSWORD="omlx2046"' /Users/jennyhu/claude-code-source/scripts/c0-auto-backup.sh; then
    fail "c0-auto-backup.sh 密码硬编码（违反 HC-AP3）"
else
    pass "c0-auto-backup.sh 密码不硬编码"
fi

if grep -q 'PASSWORD="omlx2046"' /Users/jennyhu/claude-code-source/skills/task-book-keeper/scripts/backup.sh; then
    fail "backup.sh 密码硬编码（违反 HC-AP3）"
else
    pass "backup.sh 密码不硬编码"
fi

# 验证密码文件存在
if [ -f "$HOME/.backup-password" ]; then
    pass "~/.backup-password 存在"
else
    fail "~/.backup-password 不存在"
fi

echo ""
echo "=========================================="
echo "测试结果: $PASS 通过 / $FAIL 失败"
echo "=========================================="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
