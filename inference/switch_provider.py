#!/usr/bin/env python3
"""切换 API 提供商的工具脚本"""

import json
import os
import sys

def load_config():
    config_path = os.path.join(os.path.dirname(__file__), "api_config.json")
    with open(config_path, 'r') as f:
        return json.load(f)

def save_config(config):
    config_path = os.path.join(os.path.dirname(__file__), "api_config.json")
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)

def list_providers(config):
    print("\n可用的 API 提供商:")
    print("=" * 60)
    for name, info in config["providers"].items():
        active = "✓" if name == config["active_provider"] else " "
        print(f"[{active}] {name}")
        print(f"    描述: {info.get('description', 'N/A')}")
        print(f"    Base URL: {info['base_url']}")
        print(f"    默认模型: {info['default_model']}")
        print(f"    环境变量: {info['api_key_env']}")
        
        # 检查环境变量是否已设置
        api_key = os.environ.get(info['api_key_env'])
        if api_key:
            print(f"    API Key: {api_key[:20]}...{api_key[-10:]} ✓")
        else:
            print(f"    API Key: 未设置 ✗")
        print()

def switch_provider(config, provider_name):
    if provider_name not in config["providers"]:
        print(f"错误: 未知的提供商 '{provider_name}'")
        print(f"可用的提供商: {', '.join(config['providers'].keys())}")
        return False
    
    config["active_provider"] = provider_name
    save_config(config)
    
    provider_info = config["providers"][provider_name]
    print(f"\n✓ 已切换到提供商: {provider_name}")
    print(f"  Base URL: {provider_info['base_url']}")
    print(f"  默认模型: {provider_info['default_model']}")
    print(f"  环境变量: {provider_info['api_key_env']}")
    
    # 检查环境变量
    api_key = os.environ.get(provider_info['api_key_env'])
    if not api_key:
        print(f"\n⚠ 警告: 环境变量 {provider_info['api_key_env']} 未设置")
        print(f"请运行: export {provider_info['api_key_env']}='your-api-key'")
    else:
        print(f"\n✓ API Key 已设置")
    
    return True

def add_provider(config, name, base_url, api_key_env, default_model, description=""):
    if name in config["providers"]:
        print(f"警告: 提供商 '{name}' 已存在，将被覆盖")
    
    config["providers"][name] = {
        "base_url": base_url,
        "api_key_env": api_key_env,
        "default_model": default_model,
        "description": description
    }
    save_config(config)
    print(f"\n✓ 已添加提供商: {name}")

def main():
    if len(sys.argv) < 2:
        print("用法:")
        print("  python switch_provider.py list                    # 列出所有提供商")
        print("  python switch_provider.py switch <provider>       # 切换提供商")
        print("  python switch_provider.py add <name> <base_url> <api_key_env> <model> [description]")
        print("\n示例:")
        print("  python switch_provider.py list")
        print("  python switch_provider.py switch openrouter")
        print("  python switch_provider.py switch commonstack")
        sys.exit(1)
    
    config = load_config()
    command = sys.argv[1]
    
    if command == "list":
        list_providers(config)
    
    elif command == "switch":
        if len(sys.argv) < 3:
            print("错误: 请指定提供商名称")
            print(f"可用的提供商: {', '.join(config['providers'].keys())}")
            sys.exit(1)
        provider_name = sys.argv[2]
        if not switch_provider(config, provider_name):
            sys.exit(1)
    
    elif command == "add":
        if len(sys.argv) < 6:
            print("错误: 参数不足")
            print("用法: python switch_provider.py add <name> <base_url> <api_key_env> <model> [description]")
            sys.exit(1)
        name = sys.argv[2]
        base_url = sys.argv[3]
        api_key_env = sys.argv[4]
        default_model = sys.argv[5]
        description = sys.argv[6] if len(sys.argv) > 6 else ""
        add_provider(config, name, base_url, api_key_env, default_model, description)
    
    else:
        print(f"错误: 未知的命令 '{command}'")
        print("可用的命令: list, switch, add")
        sys.exit(1)

if __name__ == "__main__":
    main()
