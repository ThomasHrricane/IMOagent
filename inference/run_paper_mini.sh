#!/bin/bash

# 论文机制小规模测试脚本
# 完全符合论文 "High-Compute Search" 机制，但使用小规模参数

# 检查环境变量
if [ -z "$OPENROUTER_API_KEY" ]; then
    echo "❌ 错误: 请设置环境变量 OPENROUTER_API_KEY"
    echo "使用方法: export OPENROUTER_API_KEY='your-api-key'"
    exit 1
fi

echo "✓ API Key 已设置"
echo ""
echo "=========================================="
echo "论文机制小规模测试"
echo "=========================================="
echo "完全符合论文 3.3.3 节机制，但使用小规模参数"
echo ""
echo "核心参数:"
echo "  N (候选池大小) = 4"
echo "  M (验证数/证明) = 4"
echo "  K (配对数) = 4"
echo "  T (最大轮次) = 3"
echo ""
echo "证明生成数: N×K = 4×4 = 16 个/轮"
echo "验证数: 16×4 = 64 个/轮"
echo "最大迭代轮次: 3 轮"
echo ""
echo "并行配置:"
echo "  - 生成进程数: 4"
echo "  - 验证进程数: 8"
echo "  - 批处理大小: 8"
echo ""
echo "提供商: OpenRouter"
echo "模型: qwen/qwen3-30b-a3b-thinking-2507"
echo "=========================================="
echo ""

# 计算预估成本
echo "预估 API 调用:"
echo ""
echo "R0 (初始化):"
echo "  生成: 4"
echo "  验证: 4 × 4 = 16"
echo "  小计: 20 次"
echo ""
echo "R1 (第1轮迭代):"
echo "  生成: 4 × 4 = 16"
echo "  验证: 16 × 4 = 64"
echo "  小计: 80 次"
echo ""
echo "R2 (第2轮迭代):"
echo "  生成: 4 × 4 = 16"
echo "  验证: 16 × 4 = 64"
echo "  小计: 80 次"
echo ""
echo "R3 (第3轮迭代):"
echo "  生成: 4 × 4 = 16"
echo "  验证: 16 × 4 = 64"
echo "  小计: 80 次"
echo ""
echo "总计:"
echo "  R0: 20 次"
echo "  R1-R3: 80 × 3 = 240 次"
echo "  ================================"
echo "  总计: 260 次 API 调用"
echo ""
echo "对比:"
echo "  - 论文精确配置 (64证明): 536,640 次"
echo "  - 当前配置 (4证明): 260 次 (0.05%)"
echo "  - 预计耗时: 5-10 分钟"
echo ""

# 询问用户确认
read -p "是否继续? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

# 清理之前的输出
echo "清理之前的测试输出..."
rm -rf ./outputs/paper_mini

# 运行测试
echo ""
echo "=========================================="
echo "开始测试..."
echo "=========================================="
echo "预计耗时: 5-10 分钟"
echo ""
echo "监控进度:"
echo "  - 查看输出文件: ls -lh ./outputs/paper_mini/proof_gen_R*/output.jsonl"
echo "  - 查看实时进度: tail -f ./outputs/paper_mini/proof_gen_R1/output.jsonl"
echo ""

uv run python main.py \
    --input_paths ../Process_temp/code/simple_test_input.json \
    --output_dirname ./outputs/paper_mini \
    --proof_pool_dirname ./outputs/paper_mini/proof_pool \
    --n_parallel_proof_gen 16 \
    --n_verification_per_proof 4 \
    --n_best_proofs_to_sample 4 \
    --n_proofs_to_refine 1 \
    --n_agg_trials 4 \
    --max_rounds 3 \
    --proof_gen_num_processes 4 \
    --proof_verification_num_processes 8 \
    --batch_size 8 \
    --skip_meta_verification \
    --model qwen/qwen3-30b-a3b-thinking-2507 \
    --proof_gen_max_len 16384 \
    --proof_verification_max_len 16384

echo ""
echo "=========================================="
echo "测试完成！"
echo "=========================================="
echo "输出目录: ./outputs/paper_mini"
echo "证明池: ./outputs/paper_mini/proof_pool"
echo ""
echo "验证机制（应该符合论文的"1变4"扩展）:"
echo ""
echo "R0 (初始化):"
echo "  - 生成: 4 个证明"
echo "  - 验证: 16 次 (4×4)"
echo "  wc -l ./outputs/paper_mini/proof_gen_R1/output.jsonl"
echo "  wc -l ./outputs/paper_mini/proof_verification_R1/output.jsonl"
echo ""
echo "R1 (第1轮迭代):"
echo "  - 输入: 4 个任务 (每个任务1个证明)"
echo "  - 生成: 16 个证明 (4×4)"
echo "  - 验证: 64 次 (16×4)"
echo "  wc -l ./outputs/paper_mini/proof_gen_R2/input.jsonl  # 应该是 4"
echo "  wc -l ./outputs/paper_mini/proof_gen_R2/output.jsonl  # 应该是 16"
echo "  wc -l ./outputs/paper_mini/proof_verification_R2/output.jsonl  # 应该是 64"
echo ""
echo "R2 (第2轮迭代):"
echo "  - 输入: 4 个任务"
echo "  - 生成: 16 个证明"
echo "  - 验证: 64 次"
echo "  wc -l ./outputs/paper_mini/proof_gen_R3/input.jsonl  # 应该是 4"
echo "  wc -l ./outputs/paper_mini/proof_gen_R3/output.jsonl  # 应该是 16"
echo "  wc -l ./outputs/paper_mini/proof_verification_R3/output.jsonl  # 应该是 64"
echo ""
echo "R3 (第3轮迭代):"
echo "  - 输入: 4 个任务"
echo "  - 生成: 16 个证明"
echo "  - 验证: 64 次"
echo "  wc -l ./outputs/paper_mini/proof_gen_R4/input.jsonl  # 应该是 4"
echo ""
echo "查看证明池统计:"
echo "  cat ./outputs/paper_mini/proof_pool/*/*.jsonl | wc -l"
echo "  # 应该有 4 + 16 + 16 + 16 = 52 个证明（如果没有提前终止）"
echo ""
echo "验证每个任务的证明数:"
echo "  cat ./outputs/paper_mini/proof_gen_R2/input.jsonl | \\"
echo "    python3 -c \"import json, sys; \\"
echo "    [print(f'Task {i+1}: {len(json.loads(line)[\\\"dep_proof_ids\\\"])} proofs') \\"
echo "     for i, line in enumerate(sys.stdin)]\""
echo "  # 每个任务应该有 1 个证明"
echo ""

