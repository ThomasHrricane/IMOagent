#!/bin/bash
# 快速切换到 CommonStack

echo "切换到 CommonStack..."
python inference/switch_provider.py switch commonstack

echo ""
echo "请设置 API Key:"
echo "export COMMONSTACK_API_KEY='ak-d40b2217417a49954df02c6743bfc2341c7e3ae9433a82f090fecf8f2b1be9d9'"
