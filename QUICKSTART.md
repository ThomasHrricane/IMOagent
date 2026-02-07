# DeepSeek-Math-V2 快速启动指南

## 环境配置

### 1. 安装 uv（如果尚未安装）
```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# 或使用 pip
pip install uv
```

### 2. 创建虚拟环境并安装依赖
```bash
# 创建虚拟环境
uv venv

# 安装依赖
uv pip install openai numpy tqdm orjson regex aiohttp
```

### 3. 设置 API Key
```bash
export COMMONSTACK_API_KEY="ak-d40b2217417a49954df02c6743bfc2341c7e3ae9433a82f090fecf8f2b1be9d9"
```

**提示**: 建议将此命令添加到 `~/.zshrc` 或 `~/.bashrc` 以便永久生效：
```bash
echo 'export COMMONSTACK_API_KEY="ak-d40b2217417a49954df02c6743bfc2341c7e3ae9433a82f090fecf8f2b1be9d9"' >> ~/.zshrc
source ~/.zshrc
```

## 运行测试

### 简单测试（1个问题）
```bash
uv run python inference/main.py \
    --input_paths Process_temp/code/simple_test_input.json \
    --output_dirname inference/outputs/simple_test \
    --proof_pool_dirname inference/outputs/simple_test/proof_pool \
    --n_parallel_proof_gen 1 \
    --n_verification_per_proof 1 \
    --proof_gen_num_processes 1 \
    --proof_verification_num_processes 1 \
    --batch_size 1 \
    --max_rounds 1 \
    --skip_meta_verification
```

### 运行 IMO 2025 题目
```bash
uv run python inference/main.py \
    --input_paths inputs/IMO2025.json \
    --output_dirname inference/outputs/imo2025 \
    --proof_pool_dirname inference/outputs/imo2025/proof_pool \
    --n_parallel_proof_gen 4 \
    --n_verification_per_proof 2 \
    --proof_gen_num_processes 4 \
    --proof_verification_num_processes 4 \
    --batch_size 4 \
    --max_rounds 3 \
    --skip_meta_verification
```

### 运行 CMO 2024 题目
```bash
uv run python inference/main.py \
    --input_paths inputs/CMO2024.json \
    --output_dirname inference/outputs/cmo2024 \
    --proof_pool_dirname inference/outputs/cmo2024/proof_pool \
    --n_parallel_proof_gen 4 \
    --n_verification_per_proof 2 \
    --max_rounds 3
```

## 参数说明

### 必需参数
- `--input_paths`: 输入文件路径（JSON 或 JSONL 格式）
- `--output_dirname`: 输出目录
- `--proof_pool_dirname`: 证明池目录

### 性能参数
- `--n_parallel_proof_gen`: 每个问题生成的并行证明数量（默认: 128）
- `--n_verification_per_proof`: 每个证明的验证次数（默认: 4）
- `--proof_gen_num_processes`: 证明生成的进程数（默认: 40）
- `--proof_verification_num_processes`: 证明验证的进程数（默认: 320）
- `--batch_size`: 批次大小（默认: 160）

### 生成参数
- `--proof_gen_temp`: 证明生成温度（默认: 1.0）
- `--proof_gen_max_len`: 证明生成最大长度（默认: 16384）
- `--proof_verification_temp`: 证明验证温度（默认: 1.0）
- `--proof_verification_max_len`: 证明验证最大长度（默认: 16384）

### 迭代参数
- `--max_rounds`: 最大迭代轮数（默认: 20）
- `--start_round`: 起始轮数（默认: 1）
- `--skip_meta_verification`: 跳过元验证（加快速度）

### 模型参数
- `--model`: 使用的模型名称（默认: `qwen/qwen3-30b-a3b-thinking-2507`）

## 输出结构

```
inference/outputs/
└── [output_dirname]/
    ├── proof_gen_R1/
    │   ├── input.jsonl          # 第1轮证明生成输入
    │   └── output.jsonl         # 第1轮证明生成输出
    ├── proof_verification_R1/
    │   ├── input.jsonl          # 第1轮证明验证输入
    │   └── output.jsonl         # 第1轮证明验证输出
    ├── meta_verification_R1/    # 元验证（如果未跳过）
    │   ├── input.jsonl
    │   └── output.jsonl
    ├── proof_gen_R2/            # 第2轮（优化后的证明）
    │   └── ...
    └── proof_pool/              # 证明池
        └── [source_name]/
            └── [problem_idx].jsonl
```

## 常见问题

### 1. API 连接失败
确保已正确设置环境变量：
```bash
echo $COMMONSTACK_API_KEY
```

### 2. 参数冲突错误
**错误**: `AssertionError: params n or batch_size are different from previous running setting`

**原因**: 使用不同参数重新运行同一输出目录

**解决方案**:
```bash
# 方案1: 删除输出目录
rm -rf inference/outputs/simple_test

# 方案2: 使用新的输出目录
--output_dirname inference/outputs/simple_test_v2
```

### 3. 超时错误
- 减少 `--proof_gen_max_len` 和 `--proof_verification_max_len`
- 减少并行进程数

### 4. 内存不足
- 减少 `--batch_size`
- 减少 `--proof_gen_num_processes` 和 `--proof_verification_num_processes`

### 5. 想要更快的结果
- 使用 `--skip_meta_verification`
- 减少 `--max_rounds`
- 减少 `--n_parallel_proof_gen` 和 `--n_verification_per_proof`

## 测试 API 配置

运行以下命令测试 API 是否正常工作：
```bash
uv run python Process_temp/code/test_api_config.py
```

## 项目结构

```
DeepSeek-Math-V2/
├── inference/              # 推理代码
│   ├── generate.py        # 生成脚本
│   ├── main.py           # 主程序
│   ├── math_templates.py # 提示词模板
│   └── utils.py          # 工具函数
├── inputs/               # 输入数据
│   ├── IMO2025.json
│   ├── CMO2024.json
│   ├── CMO2025.json
│   └── Putnam2024.json
├── Process_temp/         # 临时文件
│   ├── code/            # 测试代码
│   └── doc/             # 文档
├── change.md            # 修改记录
├── tips.md              # 项目规则
└── QUICKSTART.md        # 本文档
```

## 配置信息

- **API 端点**: `https://openrouter.ai/api/v1/chat/completions`
- **模型**: `qwen/qwen3-30b-a3b-thinking-2507`
- **虚拟环境**: uv (.venv)

## 注意事项

1. **必须使用 uv 虚拟环境**运行所有命令
2. 所有中间文档存储在 `Process_temp/doc`
3. 所有测试代码存储在 `Process_temp/code`
4. 所有修改记录在 `change.md`
5. Kimi K2.5 模型不支持 `reasoning_content`，但代码已适配

## 更多信息

- 查看 `change.md` 了解详细的修改历史
- 查看 `tips.md` 了解项目规则
- 查看 `README.md` 了解项目背景
