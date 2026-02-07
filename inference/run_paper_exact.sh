#!/bin/bash

# 论文精确配置测试脚本
# 完全符合 DeepSeekMath-V2 论文第 3.3.3 节 "High-Compute Search" 机制

# 检查环境变量
if [ -z "$OPENROUTER_API_KEY" ]; then
    echo "❌ 错误: 请设置环境变量 OPENROUTER_API_KEY"
    echo "使用方法: export OPENROUTER_API_KEY='your-api-key'"
    exit 1
fi

echo "✓ API Key 已设置"
echo ""
echo "=========================================="
echo "论文精确配置测试"
echo "=========================================="
echo "完全符合论文 3.3.3 节 High-Compute Search"
echo ""
echo "核心参数:"
echo "  N (候选池大小) = 64"
echo "  M (验证数/证明) = 64"
echo "  K (配对数) = 8"
echo "  T (最大轮次) = 16"
echo ""
echo "证明生成数: N×K = 64×8 = 512 个/轮"
echo "验证数: 512×64 = 32,768 个/轮"
echo "最大迭代轮次: 16 轮"
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
echo "R0 (初始化):"
echo "  生成: 64"
echo "  验证: 64 × 64 = 4,096"
echo "  小计: 4,160 次"
echo ""
echo "R1-R16 (每轮):"
echo "  生成: 64 × 8 = 512"
echo "  验证: 512 × 64 = 32,768"
echo "  小计: 33,280 次/轮"
echo ""
echo "总计:"
echo "  R0: 4,160 次"
echo "  R1-R16: 33,280 × 16 = 532,480 次"
echo "  ================================"
echo "  总计: 536,640 次 API 调用 ⚠️⚠️⚠️"
echo ""
echo "对比:"
echo "  - 论文完整配置 (128证明): 1,073,280 次"
echo "  - 当前配置 (512证明): 536,640 次 (减半)"
echo "  - 自定义配置 (64证明): 70,720 次"
echo "  - 小规模配置 (8证明): 120 次"
echo ""
echo "预计耗时: 数天（取决于 API 速度和配额）"
echo ""

# 询问用户确认
read -p "⚠️  这将产生极高的 API 成本（50万+次调用）。是否继续? (yes/no) " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "已取消"
    echo ""
    echo "建议使用更经济的配置:"
    echo "  - 自定义配置: ./run_custom_config.sh (7万次)"
    echo "  - 中等规模: ./run_medium_test.sh (216次)"
    echo "  - 小规模测试: 见 Process_temp/doc/测试运行指南.md"
    exit 0
fi

# 再次确认
echo ""
echo "⚠️⚠️⚠️ 最后确认 ⚠️⚠️⚠️"
echo "这将消耗大量 API 配额和时间。"
read -p "确定要继续吗? 输入 'CONFIRM' 继续: " -r
echo
if [[ $REPLY != "CONFIRM" ]]; then
    echo "已取消"
    exit 0
fi

# 清理之前的输出
echo "清理之前的测试输出..."
rm -rf ./outputs/paper_exact

# 运行测试
echo ""
echo "=========================================="
echo "开始测试..."
echo "=========================================="
echo "预计耗时: 数天"
echo "请保持网络连接和进程运行"
echo ""
echo "监控进度:"
echo "  - 查看输出文件: ls -lh ./outputs/paper_exact/proof_gen_R*/output.jsonl"
echo "  - 查看进度: tail -f ./outputs/paper_exact/proof_gen_R1/output.jsonl"
echo ""

uv run python main.py \
    --input_paths ../inputs/CMO2024.json \
    --output_dirname ./outputs/paper_exact \
    --proof_pool_dirname ./outputs/paper_exact/proof_pool \
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
    --proof_gen_max_len 16384 \
    --proof_verification_max_len 16384

echo ""
echo "=========================================="
echo "测试完成！"
echo "=========================================="
echo "输出目录: ./outputs/paper_exact"
echo "证明池: ./outputs/paper_exact/proof_pool"
echo ""
echo "查看结果:"
echo "  wc -l ./outputs/paper_exact/proof_gen_R*/output.jsonl"
echo "  wc -l ./outputs/paper_exact/proof_verification_R*/output.jsonl"
echo ""
echo "验证机制:"
echo "  R0: 应该有 64 个证明，4,096 次验证"
echo "  R1: 应该有 512 个证明，32,768 次验证"
echo "  R2: 应该有 512 个证明，32,768 次验证"
echo "  ..."
echo ""
echo "查看证明池统计:"
echo "  cat ./outputs/paper_exact/proof_pool/*/*.jsonl | wc -l"
echo ""
echo "查看 R2 输入（应该有 8 行，每行 1 个证明）:"
echo "  cat ./outputs/paper_exact/proof_gen_R2/input.jsonl | wc -l"
echo ""
echo "验证生成数量:"
echo "  # R1 应该生成 512 个证明"
echo "  wc -l ./outputs/paper_exact/proof_gen_R1/output.jsonl"
echo "  # 应该输出: 512"
echo ""
echo "  # R1 应该有 32,768 次验证"
echo "  wc -l ./outputs/paper_exact/proof_verification_R1/output.jsonl"
echo "  # 应该输出: 32768"
echo ""

