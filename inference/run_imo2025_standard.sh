#!/bin/bash

# IMO2025 标准配置测试脚本
# 使用论文标准配置测试 IMO2025 所有题目

# 检查环境变量
if [ -z "$OPENROUTER_API_KEY" ]; then
    echo "❌ 错误: 请设置环境变量 OPENROUTER_API_KEY"
    echo "使用方法: export OPENROUTER_API_KEY='your-api-key'"
    exit 1
fi

echo "✓ API Key 已设置"
echo ""
echo "=========================================="
echo "IMO2025 标准配置测试"
echo "=========================================="
echo "使用论文标准配置测试 IMO2025 所有 6 道题目"
echo ""
echo "题目列表:"
echo "  1. 线性几何问题（sunny lines）"
echo "  2. 圆几何证明"
echo "  3. 函数方程（bonza functions）"
echo "  4. 数论序列"
echo "  5. 博弈论（inekoalaty game）"
echo "  6. 组合优化（2025×2025 网格）"
echo ""
echo "标准配置（论文 3.3.3 节）:"
echo "  N (候选池大小) = 64"
echo "  M (验证数/证明) = 64"
echo "  K (配对数) = 8"
echo "  T (最大轮次) = 16"
echo ""
echo "每道题目:"
echo "  证明生成数: 512 个/轮"
echo "  验证数: 32,768 个/轮"
echo "  最大迭代轮次: 16 轮"
echo ""
echo "并行配置:"
echo "  - 生成进程数: 40"
echo "  - 验证进程数: 320"
echo "  - 批处理大小: 160"
echo ""
echo "模型: qwen/qwen3-30b-a3b-thinking-2507"
echo "提供商: OpenRouter"
echo "=========================================="
echo ""

# 计算预估成本
echo "⚠️  预估 API 调用（极高成本）:"
echo ""
echo "单题成本（如果完成所有 16 轮）:"
echo "  R0: 64 生成 + 4,096 验证 = 4,160 次"
echo "  R1-R16: (512 + 32,768) × 16 = 532,480 次"
echo "  单题总计: 536,640 次"
echo ""
echo "6 道题目总成本:"
echo "  536,640 × 6 = 3,219,840 次 API 调用 ⚠️⚠️⚠️"
echo ""
echo "实际成本（考虑提前终止）:"
echo "  - 如果题目较简单，可能在 R0-R2 就完成"
echo "  - 预计实际调用: 50万 - 200万 次"
echo "  - 预计耗时: 数天到一周"
echo ""
echo "对比:"
echo "  - 小规模配置 (N=4): 240 次/题 × 6 = 1,440 次"
echo "  - 中等配置 (N=16): 3,840 次/题 × 6 = 23,040 次"
echo "  - 标准配置 (N=64): 536,640 次/题 × 6 = 3,219,840 次"
echo ""

# 询问用户确认
read -p "⚠️  这将产生极高的 API 成本（300万+次调用）。是否继续? (yes/no) " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "已取消"
    echo ""
    echo "建议使用更经济的配置:"
    echo "  - 小规模测试: ./run_imo2025_p6.sh (240次，单题)"
    echo "  - 中等规模: 修改参数 N=16, M=16, K=4, T=4"
    exit 0
fi

# 再次确认
echo ""
echo "⚠️⚠️⚠️ 最后确认 ⚠️⚠️⚠️"
echo "这将消耗大量 API 配额和时间（可能数天）。"
echo "建议先在单题上测试，确认效果后再运行全部。"
read -p "确定要继续吗? 输入 'CONFIRM' 继续: " -r
echo
if [[ $REPLY != "CONFIRM" ]]; then
    echo "已取消"
    exit 0
fi

# 清理之前的输出
echo "清理之前的测试输出..."
rm -rf ./outputs/imo2025_standard

# 运行测试
echo ""
echo "=========================================="
echo "开始测试..."
echo "=========================================="
echo "预计耗时: 数天到一周"
echo "请保持网络连接和进程运行"
echo ""
echo "监控进度:"
echo "  - 查看输出文件: ls -lh ./outputs/imo2025_standard/proof_gen_R*/output.jsonl"
echo "  - 查看实时进度: tail -f ./outputs/imo2025_standard/proof_gen_R1/output.jsonl"
echo "  - 查看证明池: cat ./outputs/imo2025_standard/proof_pool/*/*.jsonl | wc -l"
echo ""
echo "提示:"
echo "  - 可以随时 Ctrl+C 中断"
echo "  - 已完成的轮次会被保存"
echo "  - 重新运行会从中断处继续"
echo ""

uv run python main.py \
    --input_paths ../inputs/IMO2025.json \
    --output_dirname ./outputs/imo2025_standard \
    --proof_pool_dirname ./outputs/imo2025_standard/proof_pool \
    --n_parallel_proof_gen 512 \
    --n_verification_per_proof 64 \
    --n_best_proofs_to_sample 64 \
    --n_proofs_to_refine 1 \
    --n_agg_trials 8 \
    --max_rounds 16 \
    --proof_gen_num_processes 40 \
    --proof_verification_num_processes 320 \
    --batch_size 160 \
    --skip_meta_verification \
    --model qwen/qwen3-30b-a3b-thinking-2507 \
    --proof_gen_max_len 32768 \
    --proof_verification_max_len 32768

echo ""
echo "=========================================="
echo "测试完成！"
echo "=========================================="
echo "输出目录: ./outputs/imo2025_standard"
echo "证明池: ./outputs/imo2025_standard/proof_pool"
echo ""
echo "查看结果:"
echo ""
echo "1. 各轮生成和验证数量:"
echo "   wc -l ./outputs/imo2025_standard/proof_gen_R*/output.jsonl"
echo "   wc -l ./outputs/imo2025_standard/proof_verification_R*/output.jsonl"
echo ""
echo "2. 证明池统计（按题目）:"
echo "   for dir in ./outputs/imo2025_standard/proof_pool/*/; do"
echo "     echo \"题目: \$(basename \$dir)\""
echo "     cat \$dir/*.jsonl | wc -l"
echo "   done"
echo ""
echo "3. 查看每道题的质量分布:"
echo "   for dir in ./outputs/imo2025_standard/proof_pool/*/; do"
echo "     echo \"=== \$(basename \$dir) ===\""
echo "     cat \$dir/*.jsonl | python3 -c \\"
echo "       \"import json, sys; \\"
echo "       scores = [json.loads(line)['meanscore'] for line in sys.stdin]; \\"
echo "       print(f'证明数: {len(scores)}'); \\"
echo "       print(f'平均分: {sum(scores)/len(scores):.4f}'); \\"
echo "       print(f'最高分: {max(scores):.4f}'); \\"
echo "       print(f'满分数: {sum(1 for s in scores if s > 0.99999)}'); \\"
echo "       print()\""
echo "   done"
echo ""
echo "4. 按轮次查看证明数（所有题目）:"
echo "   cat ./outputs/imo2025_standard/proof_pool/*/*.jsonl | \\"
echo "     python3 -c \"import json, sys; \\"
echo "     from collections import Counter; \\"
echo "     rounds = [json.loads(line)['round_idx'] for line in sys.stdin]; \\"
echo "     counter = Counter(rounds); \\"
echo "     [print(f'R{r-1}: {counter[r]} 个证明') for r in sorted(counter.keys())]\""
echo ""
echo "5. 查看每道题的最佳证明:"
echo "   for dir in ./outputs/imo2025_standard/proof_pool/*/; do"
echo "     echo \"=== \$(basename \$dir) ===\""
echo "     cat \$dir/*.jsonl | python3 -c \\"
echo "       \"import json, sys; \\"
echo "       proofs = [json.loads(line) for line in sys.stdin]; \\"
echo "       best = max(proofs, key=lambda x: x['meanscore']); \\"
echo "       print(f'最佳证明 (R{best[\\\"round_idx\\\"]-1}, 分数: {best[\\\"meanscore\\\"]:.4f})'); \\"
echo "       print(best['proof'][:500] + '...'); \\"
echo "       print()\""
echo "   done"
echo ""
echo "6. 统计 API 调用总数:"
echo "   total=0"
echo "   for file in ./outputs/imo2025_standard/proof_gen_R*/output.jsonl \\"
echo "               ./outputs/imo2025_standard/proof_verification_R*/output.jsonl; do"
echo "     count=\$(wc -l < \$file 2>/dev/null || echo 0)"
echo "     total=\$((total + count))"
echo "   done"
echo "   echo \"总 API 调用数: \$total\""
echo ""
