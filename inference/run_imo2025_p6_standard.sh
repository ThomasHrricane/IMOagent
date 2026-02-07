#!/bin/bash

# IMO2025 第6题测试脚本
# 使用论文标准配置测试单题

# 检查环境变量
if [ -z "$OPENROUTER_API_KEY" ]; then
    echo "❌ 错误: 请设置环境变量 OPENROUTER_API_KEY"
    echo "使用方法: export OPENROUTER_API_KEY='your-api-key'"
    exit 1
fi

echo "✓ API Key 已设置"
echo ""
echo "=========================================="
echo "IMO2025 第6题 - 论文标准配置测试"
echo "=========================================="
echo "题目: 2025×2025 网格组合优化问题"
echo ""
echo "论文标准配置（3.3.3 节）:"
echo "  N (候选池大小) = 64"
echo "  M (验证数/证明) = 64"
echo "  K (配对数) = 8"
echo "  T (最大轮次) = 16"
echo ""
echo "预估成本（单题）:"
echo "  R0: 64 生成 + 4,096 验证 = 4,160 次"
echo "  R1-R16: (512 + 32,768) × 16 = 532,480 次"
echo "  理论最大: 536,640 次 API 调用"
echo ""
echo "实际成本（考虑提前终止）:"
echo "  - 如果题目较简单: 5万-10万次"
echo "  - 如果题目中等: 10万-30万次"
echo "  - 如果题目困难: 30万-50万次"
echo ""
echo "预计耗时: 数小时到1-2天"
echo ""
echo "并行配置:"
echo "  - 生成进程数: 20 (降低以减少超时)"
echo "  - 验证进程数: 160"
echo "  - 批处理大小: 80"
echo ""
echo "模型: qwen/qwen3-30b-a3b-thinking-2507"
echo "提供商: OpenRouter"
echo "=========================================="
echo ""

# 询问用户确认
read -p "⚠️  这将产生较高的 API 成本（预计5万-50万次调用）。是否继续? (yes/no) " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "已取消"
    echo ""
    echo "建议使用更经济的配置:"
    echo "  - 小规模测试: ./run_imo2025_p6.sh (~240次)"
    echo "  - 中等规模: N=16, M=16, K=4, T=4 (~3,840次)"
    exit 0
fi

# 清理之前的输出
echo "清理之前的测试输出..."
rm -rf ./outputs/imo2025_p6_standard

# 运行测试
echo ""
echo "=========================================="
echo "开始测试..."
echo "=========================================="
echo "预计耗时: 数小时到1-2天"
echo "请保持网络连接和进程运行"
echo ""
echo "监控进度:"
echo "  - 查看输出文件: ls -lh ./outputs/imo2025_p6_standard/proof_gen_R*/output.jsonl"
echo "  - 查看实时进度: tail -f ./outputs/imo2025_p6_standard/proof_gen_R1/output.jsonl"
echo "  - 查看证明池: cat ./outputs/imo2025_p6_standard/proof_pool/*/*.jsonl | wc -l"
echo ""
echo "提示:"
echo "  - 可以随时 Ctrl+C 中断"
echo "  - 已完成的轮次会被保存"
echo "  - 重新运行会从中断处继续"
echo ""

uv run python main.py \
    --input_paths ../inputs/IMO2025_P6.json \
    --output_dirname ./outputs/imo2025_p6_standard \
    --proof_pool_dirname ./outputs/imo2025_p6_standard/proof_pool \
    --n_parallel_proof_gen 512 \
    --n_verification_per_proof 64 \
    --n_best_proofs_to_sample 64 \
    --n_proofs_to_refine 1 \
    --n_agg_trials 8 \
    --max_rounds 16 \
    --proof_gen_num_processes 20 \
    --proof_verification_num_processes 160 \
    --batch_size 80 \
    --skip_meta_verification \
    --model qwen/qwen3-30b-a3b-thinking-2507 \
    --proof_gen_max_len 32768 \
    --proof_verification_max_len 32768

echo ""
echo "=========================================="
echo "测试完成！"
echo "=========================================="
echo "输出目录: ./outputs/imo2025_p6_standard"
echo "证明池: ./outputs/imo2025_p6_standard/proof_pool"
echo ""
echo "查看结果:"
echo ""
echo "1. 各轮生成和验证数量:"
echo "   wc -l ./outputs/imo2025_p6_standard/proof_gen_R*/output.jsonl"
echo "   wc -l ./outputs/imo2025_p6_standard/proof_verification_R*/output.jsonl"
echo ""
echo "2. 证明池统计:"
echo "   cat ./outputs/imo2025_p6_standard/proof_pool/*/*.jsonl | wc -l"
echo ""
echo "3. 查看证明质量分布:"
echo "   cat ./outputs/imo2025_p6_standard/proof_pool/*/*.jsonl | \\"
echo "     python3 -c \"import json, sys; \\"
echo "     scores = [json.loads(line)['meanscore'] for line in sys.stdin]; \\"
echo "     print(f'总证明数: {len(scores)}'); \\"
echo "     print(f'平均分: {sum(scores)/len(scores):.4f}'); \\"
echo "     print(f'最高分: {max(scores):.4f}'); \\"
echo "     print(f'最低分: {min(scores):.4f}'); \\"
echo "     print(f'满分证明数: {sum(1 for s in scores if s > 0.99999)}');\""
echo ""
echo "4. 按轮次查看证明数:"
echo "   cat ./outputs/imo2025_p6_standard/proof_pool/*/*.jsonl | \\"
echo "     python3 -c \"import json, sys; \\"
echo "     from collections import Counter; \\"
echo "     rounds = [json.loads(line)['round_idx'] for line in sys.stdin]; \\"
echo "     counter = Counter(rounds); \\"
echo "     [print(f'R{r-1}: {counter[r]} 个证明') for r in sorted(counter.keys())]\""
echo ""
echo "5. 查看最佳证明:"
echo "   cat ./outputs/imo2025_p6_standard/proof_pool/*/*.jsonl | \\"
echo "     python3 -c \"import json, sys; \\"
echo "     proofs = [json.loads(line) for line in sys.stdin]; \\"
echo "     best = max(proofs, key=lambda x: x['meanscore']); \\"
echo "     print(f'最佳证明 (R{best[\\\"round_idx\\\"]-1}, 分数: {best[\\\"meanscore\\\"]:.4f}):'); \\"
echo "     print(best['proof'][:500] + '...')\""
echo ""
echo "6. 统计 API 调用总数:"
echo "   total=0"
echo "   for file in ./outputs/imo2025_p6_standard/proof_gen_R*/output.jsonl \\"
echo "               ./outputs/imo2025_p6_standard/proof_verification_R*/output.jsonl; do"
echo "     count=\$(wc -l < \$file 2>/dev/null || echo 0)"
echo "     total=\$((total + count))"
echo "   done"
echo "   echo \"总 API 调用数: \$total\""
echo ""
