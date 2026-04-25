#!/bin/bash
# claude-usage-monitor: Claude 额度消耗计算

set -e

# Claude 模型定价 (每百万 tokens)
HAIKU_INPUT=0.08
HAIKU_OUTPUT=0.24
SONNET_INPUT=3.0
SONNET_OUTPUT=15.0
OPUS_INPUT=15.0
OPUS_OUTPUT=75.0

# 任务类型估算 (tokens)
TASK_ESTIMATES=(
    "simple_query:1000"
    "doc_generation:5000"
    "code_generation:3000"
    "complex_reasoning:10000"
)

calculate_cost() {
    local model="$1"
    local input_tokens="$2"
    local output_tokens="$3"
    
    local input_rate output_rate
    case $model in
        haiku-4.5)
            input_rate=$HAIKU_INPUT
            output_rate=$HAIKU_OUTPUT
            ;;
        sonnet-4.6)
            input_rate=$SONNET_INPUT
            output_rate=$SONNET_OUTPUT
            ;;
        opus-4.6|opus-4.7)
            input_rate=$OPUS_INPUT
            output_rate=$OPUS_OUTPUT
            ;;
        *)
            echo "❌ 未知模型: $model"
            return 1
            ;;
    esac
    
    local input_cost=$(echo "scale=4; $input_tokens * $input_rate / 1000000" | bc)
    local output_cost=$(echo "scale=4; $output_tokens * $output_rate / 1000000" | bc)
    local total_cost=$(echo "scale=4; $input_cost + $output_cost" | bc)
    
    echo "模型: $model"
    echo "输入: $input_tokens tokens (¥$input_cost)"
    echo "输出: $output_tokens tokens (¥$output_cost)"
    echo "总计: ¥$total_cost"
}

estimate_by_task() {
    local task_type="$1"
    local model="${2:-haiku-4.5}"
    
    local tokens
    case $task_type in
        simple_query) tokens=1000 ;;
        doc_generation) tokens=5000 ;;
        code_generation) tokens=3000 ;;
        complex_reasoning) tokens=10000 ;;
        *) tokens=5000 ;;
    esac
    
    # 假设输出 = 输入的 50%
    local output_tokens=$(echo "scale=0; $tokens * 0.5 / 1" | bc)
    
    calculate_cost "$model" "$tokens" "$output_tokens"
}

optimize_model() {
    local task_type="$1"
    
    echo "=== 任务: $task_type ==="
    echo ""
    echo "模型对比:"
    echo ""
    
    for model in haiku-4.5 sonnet-4.6 opus-4.7; do
        estimate_by_task "$task_type" "$model"
        echo ""
    done
    
    echo "建议: "
    case $task_type in
        simple_query) echo "  使用 Haiku 4.5，成本最低" ;;
        doc_generation) echo "  使用 Sonnet 4.6，性价比最高" ;;
        code_generation) echo "  使用 Sonnet 4.6，平衡成本和能力" ;;
        complex_reasoning) echo "  使用 Opus 4.7，保证质量" ;;
    esac
}

# 主逻辑
case "${1:-help}" in
    calculate)
        calculate_cost "${2:-haiku-4.5}" "${3:-5000}" "${4:-2500}"
        ;;
    estimate)
        estimate_by_task "${2:-simple_query}" "${3:-haiku-4.5}"
        ;;
    optimize)
        optimize_model "${2:-doc_generation}"
        ;;
    help|*)
        echo "Claude 额度消耗计算器"
        echo ""
        echo "用法:"
        echo "  $0 calculate <model> <input_tokens> <output_tokens>"
        echo "  $0 estimate <task_type> [model]"
        echo "  $0 optimize <task_type>"
        echo ""
        echo "任务类型: simple_query, doc_generation, code_generation, complex_reasoning"
        echo "模型: haiku-4.5, sonnet-4.6, opus-4.6, opus-4.7"
        ;;
esac
