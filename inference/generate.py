import os
import json
import pickle
import math
import argparse
import asyncio
import aiohttp

from tqdm import tqdm
from multiprocessing import Queue, Process
from time import time, sleep

from openai import AsyncOpenAI
import httpx

def load_api_config():
    """加载 API 配置"""
    config_path = os.path.join(os.path.dirname(__file__), "api_config.json")
    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
        return config
    except FileNotFoundError:
        # 如果配置文件不存在，返回默认配置
        return {
            "providers": {
                "commonstack": {
                    "base_url": "https://api.commonstack.ai/v1",
                    "api_key_env": "COMMONSTACK_API_KEY",
                    "default_model": "moonshotai/kimi-k2.5"
                }
            },
            "active_provider": "commonstack"
        }

class APIModel:
    def __init__(self, model=None, provider=None, verbose=True):
        # 加载配置
        config = load_api_config()
        
        # 确定使用哪个提供商
        if provider is None:
            provider = config.get("active_provider", "commonstack")
        
        if provider not in config["providers"]:
            raise ValueError(f"未知的提供商: {provider}. 可用的提供商: {list(config['providers'].keys())}")
        
        provider_config = config["providers"][provider]
        
        # 获取 API key
        api_key_env = provider_config["api_key_env"]
        api_key = os.environ.get(api_key_env, "")
        if not api_key:
            raise ValueError(f"请设置环境变量 {api_key_env}")
        
        # 确定使用的模型
        if model is None:
            model = provider_config["default_model"]
        
        # 获取 base_url
        base_url = provider_config["base_url"]
        
        # 只在主进程打印配置信息（通过 verbose 参数控制）
        if verbose:
            print(f"使用 API 提供商: {provider}")
            print(f"Base URL: {base_url}")
            print(f"Model: {model}")
        
        # 创建自定义 httpx 客户端，配置详细的超时设置
        http_client = httpx.AsyncClient(
            timeout=httpx.Timeout(
                connect=60.0,   # 连接超时
                read=600.0,     # 读取超时（10分钟，适应大规模生成）
                write=60.0,     # 写入超时
                pool=60.0       # 连接池超时
            ),
            limits=httpx.Limits(
                max_connections=200,        # 增加到 200（适应更高并发）
                max_keepalive_connections=50  # 增加到 50
            )
        )
        
        self.client = AsyncOpenAI(
            api_key=api_key,
            timeout=300.0,
            base_url=base_url,
            max_retries=2,
            http_client=http_client
        )
        self.model = model
        self.provider = provider

    async def generate_one(self, prompt, sampling_params):
        try:
            res = await self.client.chat.completions.create(
                model=self.model,
                messages=prompt,
                stream=False,
                **sampling_params
            )
            
            # 检查响应是否有效
            if res is None or not res.choices:
                print(f"警告: API 返回空响应")
                return "", "error"
            
            # 安全处理可能为 None 的响应
            message = res.choices[0].message
            reasoning_content = getattr(message, 'reasoning_content', None) or ""
            content = getattr(message, 'content', None) or ""
            
            # 如果模型不支持 reasoning_content，直接使用 content
            if reasoning_content:
                output_string = f"<think>\n{reasoning_content.strip()}"
                if content:
                    output_string += f"\n</think>\n{content.strip()}"
                else:
                    output_string += "\n</think>"
            else:
                # 对于不支持 reasoning_content 的模型，添加空的 <think> 标签以保持格式一致
                output_string = f"<think>\n\n</think>\n{content.strip()}" if content else ""
            
            # 安全处理 finish_reason（可能为 None）
            finish_reason = res.choices[0].finish_reason
            if finish_reason is None:
                finish_reason = "unknown"
            
            return output_string, finish_reason
            
        except Exception as e:
            print(f"错误: API 调用失败 - {e}")
            return "", "error"

    async def generate_all(self, data):
        tasks = [self.generate_one(task['prompt'], task['sampling_params']) for i, task in enumerate(data)]
        results = await asyncio.gather(*tasks)
        return results

    def generate(self, input_data, sampling_params):
        data = []
        for item in input_data:
            if "messages" not in item:
                messages = [{
                    "role": "user",
                    "content": item["prompt"],
                }]
            else:
                messages = item['messages']
            data.append({
                'prompt': messages,
                'sampling_params': sampling_params
            })

        outputs = asyncio.run(self.generate_all(data))
        output_data = []
        assert len(input_data) == len(outputs)
        for item, (output_string, finish_reason) in zip(input_data, outputs):
            output_data.append({
                **item,
                "output": output_string,
                "finish_reason": finish_reason.lower(),
            })
        return output_data

    def mp_generate(self, input_queue: Queue, output_queue: Queue, sampling_params):
        while True:
            batch_idx, input_data = input_queue.get()
            if input_data is None:
                output_queue.put((batch_idx, None))
                break
            output_data = self.generate(input_data, sampling_params)
            output_queue.put((batch_idx, output_data))


def mp_generate_loop(input_queue, output_queue, sampling_params, model="qwen/qwen3-30b-a3b-thinking-2507"):
    # 在子进程中禁用打印，避免重复输出
    api_model = APIModel(model=model, verbose=False)
    sleep(5)
    api_model.mp_generate(input_queue, output_queue, sampling_params)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_data_path", required=True)
    parser.add_argument("--output_data_path", required=True)
    parser.add_argument("--num_processes", default=16, type=int)
    parser.add_argument("--batch_size", default=16, type=int)
    parser.add_argument("--temperature", required=True, type=float)
    parser.add_argument("--top_p", required=True, type=float)
    parser.add_argument("--max_tokens", required=True, type=int)
    parser.add_argument("--n", required=True, type=int)
    parser.add_argument("--model", default="qwen/qwen3-30b-a3b-thinking-2507", type=str, help="Model name to use")
    args, _ = parser.parse_known_args()
    input_data_path, output_data_path = args.input_data_path, args.output_data_path
    os.makedirs(os.path.dirname(output_data_path), exist_ok=True)

    num_processes = args.num_processes
    batch_size = args.batch_size
    temperature = args.temperature
    top_p = args.top_p
    max_tokens = args.max_tokens
    n = args.n

    meta_data_path = f"{output_data_path}.meta"
    if not os.path.exists(meta_data_path):
        meta_data = {"n": n, "batch_size": batch_size, "complete_batches": []}
        with open(meta_data_path, "wb") as f:
            pickle.dump(meta_data, f)
    with open(meta_data_path, "rb") as f:
        meta_data = pickle.load(f)
    meta_data["complete_batches"] = set(meta_data["complete_batches"])

    assert n == meta_data["n"] and batch_size == meta_data["batch_size"], \
        f"params n or batch_size are different from previous running setting({n}, {batch_size}) != ({meta_data['n']}, {meta_data['batch_size']}), you need to delete {output_data_path} & {meta_data_path} to clear existing results"

    sampling_params = dict(
        temperature=temperature,
        top_p=top_p,
        max_tokens=max_tokens
    )
    
    # 在主进程中打印一次配置信息
    print(f"\n{'='*60}")
    print(f"API 配置")
    print(f"{'='*60}")
    config = load_api_config()
    active_provider = config.get("active_provider", "commonstack")
    provider_config = config["providers"][active_provider]
    print(f"提供商: {active_provider}")
    print(f"Base URL: {provider_config['base_url']}")
    print(f"模型: {args.model}")
    print(f"进程数: {num_processes}")
    print(f"批次大小: {batch_size}")
    print(f"{'='*60}\n")

    input_queue, output_queue = Queue(), Queue()
    fr = open(input_data_path, "r", encoding="utf-8")
    fw = open(output_data_path, "a+", encoding="utf-8")

    processes = []
    
    for i in range(num_processes):
        process = Process(target=mp_generate_loop, args=(input_queue, output_queue, sampling_params, args.model))
        process.start()
        processes.append(process)

    submit_batch = []
    num_input = 0
    num_skip = 0
    batch_idx = 0

    for line in tqdm(fr, desc="Waiting Input"):
        item = json.loads(line)
        for i in range(n):
            submit_batch.append(item)
            if len(submit_batch) >= batch_size:
                if batch_idx not in meta_data["complete_batches"]:
                    num_input += batch_size
                    input_queue.put((batch_idx, submit_batch))
                else:
                    num_skip += batch_size
                batch_idx += 1
                submit_batch = []
    if len(submit_batch) > 0:
        if batch_idx not in meta_data["complete_batches"]:
            input_queue.put((batch_idx, submit_batch))
            num_input += len(submit_batch)
        else:
            num_skip += len(submit_batch)
    print(f"Total Input Samples: {num_input} (Skip {num_skip} Samples)")
    fr.close()

    for i in range(num_processes):
        input_queue.put((None, None))

    remain_processes = num_processes
    num_output = 0
    with tqdm(desc="Waiting Output", total=num_input) as pbar:
        while remain_processes > 0:
            batch_idx, output_data = output_queue.get()
            if output_data is None:
                remain_processes -= 1
                continue
            for item in output_data:
                print(json.dumps(item, ensure_ascii=False), file=fw, flush=True)
                num_output += 1
                pbar.update(1)
            meta_data["complete_batches"].add(batch_idx)
            with open(meta_data_path, "wb") as f:
                pickle.dump(meta_data, f)
            fw.flush()
    print(f"Total Output Samples: {num_output}")
    fw.close()
    [process.join() for process in processes]
