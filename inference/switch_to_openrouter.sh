#!/bin/bash
# 快速切换到 OpenRouter

echo "切换到 OpenRouter..."
python inference/switch_provider.py switch openrouter

echo ""
echo "请设置 API Key:"
echo "export OPENROUTER_API_KEY='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'"
