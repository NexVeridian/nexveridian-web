+++
title = "LLM Inference Benchmarks - Apple M4 Max 48GB 16 Core 16-inch using LM Studio"
date = 2025-05-06

[taxonomies]
tags = ["llm", "benchmarks", "llm-benchmarks", "lm-studio"]
+++

| Size (B) | Speed (T/s) | Model               | Type | Quant  | Spec Dec (B) | Spec Quant |
|----------|-------------|---------------------|------|--------|--------------|------------|
| 1.5      | 282         | qwen 2.5            | MLX  | 4      | -            | -          |
| 1.5      | 76          | qwen 2.5            | MLX  | 8      | -            | -          |
| 7        | 70          | qwen 2.5            | GUFF | Q4_K_M | -            | -          |
| 7        | 101         | qwen 2.5            | MLX  | 4      | -            | -          |
| 7        | 58          | qwen 2.5            | MLX  | 8      | -            | -          |
| 12       | 35          | wayfarer            | GUFF | Q6_K   | -            | -          |
| 12       | 65          | wayfarer            | MLX  | 4      | -            | -          |
| 12       | 45          | wayfarer            | MLX  | 6      | -            | -          |
| 12       | 36          | wayfarer            | MLX  | 8      | -            | -          |
| 14       | 36          | qwen 2.5            | GUFF | Q4_K_M | -            | -          |
| 14       | 52          | qwen 2.5            | MLX  | 4      | -            | -          |
| 14       | 55          | qwen 2.5            | MLX  | 4      | 1.5          | 4          |
| 14       | 30          | qwen 2.5            | MLX  | 8      | -            | -          |
| 24       | 35          | mistral small 3     | MLX  | 4      | -            | -          |
| 32       | 18          | qwen 2.5            | GUFF | Q4_K_M | -            | -          |
| 32       | 23          | qwen 2.5            | MLX  | 4      | -            | -          |
| 32       | 30          | qwen 2.5            | MLX  | 4      | 1.5          | 4          |
| 32       | 30          | qwen 2.5            | MLX  | 4      | 1.5          | 4          |
| 32       | 34          | qwen 2.5            | MLX  | 4      | 1.5          | 8          |
| 32       | 26          | qwen 2.5 r1         | MLX  | 4      | 1.5          | 4          |
| 32       | 33          | qwen 2.5 coder      | MLX  | 4      | 1.5          | 4          |
| 32       | 31          | qwen 2.5 coder      | MLX  | 4      | 3            | 4          |
| 32       | 25          | qwq                 | MLX  | 3      | -            | -          |
| 32       | 24          | qwq                 | MLX  | 4      | -            | -          |
| 32       | 18          | qwq                 | MLX  | 4      | 1.5          | 4          |
| 32       | 22          | qwq                 | MLX  | 4      | 1.5          | 8          |
| 32       | 16          | qwq                 | MLX  | 4      | 7            | 4          |
| 32       | 16          | qwq                 | MLX  | 4      | 7            | 8          |
| 32       | 16          | qwq                 | MLX  | 6      | -            | -          |
| 32       | 16          | qwq                 | MLX  | 6      | 1.5          | 4          |
| 32       | 16          | qwq                 | MLX  | 6      | 1.5          | 8          |
| 70       | 12          | wayfarer large      | GUFF | Q2_K_S | -            | -          |
| 70       | 15          | wayfarer large      | MLX  | 3      | -            | -          |
| 30 - A3  | 93          | qwen 3              | MLX  | 4      | -            | -          |
| 30 - A3  | 76          | qwen 3              | MLX  | 4      | 1.7          | 4          |
| 30 - A3  | 81          | qwen 3              | MLX  | 6      | -            | -          |
| 30 - A3  | 70          | qwen 3              | MLX  | 6      | 1.7          | 4          |
| 30 - A3  | 70          | qwen 3              | MLX  | 8      | -            | -          |
| 32       | 22          | qwen 3              | MLX  | 4      | -            | -          |
| 32       | 26          | qwen 3              | MLX  | 4      | 1.7          | 4          |
| 24       | 18          | Devstral Small 2507 | MLX  | 8      | -            | -          |

# mlx convert and upload to huggingface
https://huggingface.co/docs/hub/en/mlx

https://huggingface.co/mlx-community

git clone git@github.com:NexVeridian/NexVeridian-web.git
```bash
just uv

just mlx_create "Qwen/QwQ-32B" "4 6 8" "/Users/elijahmcmorris/.cache/lm-studio/models" "mlx-community" fasle false
# or
uv venv
uv pip install huggingface_hub hf_transfer mlx_lm
uv run huggingface-cli login

uv run mlx_lm.convert --hf-path Qwen/QwQ-32B -q --q-bits 4 --upload-repo mlx-community/QwQ-32B-4bit --mlx-path /Users/elijahmcmorris/.cache/lm-studio/models/mlx-community/QwQ-32B-4bit
```
or use https://huggingface.co/spaces/mlx-community/mlx-my-repo

# LLM Settings.md
## Qwen 3
| Temp | Min P | Top P | Top K | Repeat P |
|------|-------|-------|-------|----------|
| 0.6  | 0.00  | 0.95  | 20    | -        |

## Qwen 3 `/no_think`
| Temp | Min P | Top P | Top K | Repeat P |
|------|-------|-------|-------|----------|
| 0.7  | 0.00  | 0.80  | 20    | 1.5      |
