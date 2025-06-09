+++
title = "LLM Inference Benchmarks - Apple M4 Max 48GB 16 Core 16-inch using LM Studio"
date = 2025-05-06

[taxonomies]
tags = ["llm", "benchmarks", "llm-benchmarks", "lm-studio"]
+++

| Size (B) | Speed (T/s) | Model           | Type | Quant  | Spec Dec (B) | Spec Quant |
|----------|-------------|-----------------|------|--------|--------------|------------|
| 1.5      | 282         | qwen 2.5        | MLX  | 4      | -            | -          |
| 1.5      | 76          | qwen 2.5        | MLX  | 8      | -            | -          |
| 7        | 70          | qwen 2.5        | GUFF | Q4_K_M | -            | -          |
| 7        | 101         | qwen 2.5        | MLX  | 4      | -            | -          |
| 7        | 58          | qwen 2.5        | MLX  | 8      | -            | -          |
| 12       | 35          | wayfarer        | GUFF | Q6_K   | -            | -          |
| 12       | 65          | wayfarer        | MLX  | 4      | -            | -          |
| 12       | 45          | wayfarer        | MLX  | 6      | -            | -          |
| 12       | 36          | wayfarer        | MLX  | 8      | -            | -          |
| 14       | 36          | qwen 2.5        | GUFF | Q4_K_M | -            | -          |
| 14       | 52          | qwen 2.5        | MLX  | 4      | -            | -          |
| 14       | 55          | qwen 2.5        | MLX  | 4      | 1.5          | 4          |
| 14       | 30          | qwen 2.5        | MLX  | 8      | -            | -          |
| 24       | 35          | mistral small 3 | MLX  | 4      | -            | -          |
| 32       | 18          | qwen 2.5        | GUFF | Q4_K_M | -            | -          |
| 32       | 23          | qwen 2.5        | MLX  | 4      | -            | -          |
| 32       | 30          | qwen 2.5        | MLX  | 4      | 1.5          | 4          |
| 32       | 30          | qwen 2.5        | MLX  | 4      | 1.5          | 4          |
| 32       | 34          | qwen 2.5        | MLX  | 4      | 1.5          | 8          |
| 32       | 26          | qwen 2.5 r1     | MLX  | 4      | 1.5          | 4          |
| 32       | 33          | qwen 2.5 coder  | MLX  | 4      | 1.5          | 4          |
| 32       | 31          | qwen 2.5 coder  | MLX  | 4      | 3            | 4          |
| 32       | 25          | qwq             | MLX  | 3      | -            | -          |
| 32       | 24          | qwq             | MLX  | 4      | -            | -          |
| 32       | 18          | qwq             | MLX  | 4      | 1.5          | 4          |
| 32       | 22          | qwq             | MLX  | 4      | 1.5          | 8          |
| 32       | 16          | qwq             | MLX  | 4      | 7            | 4          |
| 32       | 16          | qwq             | MLX  | 4      | 7            | 8          |
| 32       | 16          | qwq             | MLX  | 6      | -            | -          |
| 32       | 16          | qwq             | MLX  | 6      | 1.5          | 4          |
| 32       | 16          | qwq             | MLX  | 6      | 1.5          | 8          |
| 70       | 12          | wayfarer large  | GUFF | Q2_K_S | -            | -          |
| 70       | 15          | wayfarer large  | MLX  | 3      | -            | -          |
| 30 - A3  | 93          | qwen 3          | MLX  | 4      | -            | -          |
| 30 - A3  | 76          | qwen 3          | MLX  | 4      | 1.7          | 4          |
| 30 - A3  | 81          | qwen 3          | MLX  | 6      | -            | -          |
| 30 - A3  | 70          | qwen 3          | MLX  | 6      | 1.7          | 4          |
| 30 - A3  | 70          | qwen 3          | MLX  | 8      | -            | -          |
| 32       | 22          | qwen 3          | MLX  | 4      | -            | -          |
| 32       | 26          | qwen 3          | MLX  | 4      | 1.7          | 4          |

# mlx convert and upload to huggingface
https://huggingface.co/docs/hub/en/mlx

https://huggingface.co/mlx-community

```bash
uv venv
uv pip install huggingface_hub hf_transfer mlx_lm
uv run huggingface-cli login

just mlx_create "Qwen/QwQ-32B" "4 6 8" "/Users/elijahmcmorris/.cache/lm-studio/models" "false"
# or
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

## QWQ
| Temp | Min P | Top P | Repeat P |
|------|-------|-------|----------|
| 0.7  | 0.05  | 0.95  | -        |
| 1.5  | 0.10  | 1.00  | -        |

## Prompt Template
```
{%- if tools %}
    {{- '<|im_start|>system\n' }}
    {%- if messages[0].role == 'system' %}
        {{- messages[0].content + '\n\n' }}
    {%- endif %}
    {{- "# Tools\n\nYou may call one or more functions to assist with the user query.\n\nYou are provided with function signatures within <tools></tools> XML tags:\n<tools>" }}
    {%- for tool in tools %}
        {{- "\n" }}
        {{- tool | tojson }}
    {%- endfor %}
    {{- "\n</tools>\n\nFor each function call, return a json object with function name and arguments within <tool_call></tool_call> XML tags:\n<tool_call>\n{\"name\": <function-name>, \"arguments\": <args-json-object>}\n</tool_call><|im_end|>\n" }}
{%- else %}
    {%- if messages[0].role == 'system' %}
        {{- '<|im_start|>system\n' + messages[0].content + '<|im_end|>\n' }}
    {%- endif %}
{%- endif %}
{%- set ns = namespace(multi_step_tool=true, last_query_index=messages|length - 1) %}
{%- for message in messages[::-1] %}
    {%- set index = (messages|length - 1) - loop.index0 %}
    {%- set tool_start = "<tool_response>" %}
    {%- set tool_start_length = tool_start|length %}
    {%- set start_of_message = message.content[:tool_start_length] %}
    {%- set tool_end = "</tool_response>" %}
    {%- set tool_end_length = tool_end|length %}
    {%- set start_pos = (message.content|length) - tool_end_length %}
    {%- if start_pos < 0 %}
        {%- set start_pos = 0 %}
    {%- endif %}
    {%- set end_of_message = message.content[start_pos:] %}
    {%- if ns.multi_step_tool and message.role == "user" and not(start_of_message == tool_start and end_of_message == tool_end) %}
        {%- set ns.multi_step_tool = false %}
        {%- set ns.last_query_index = index %}
    {%- endif %}
{%- endfor %}
{%- for message in messages %}
    {%- if (message.role == "user") or (message.role == "system" and not loop.first) %}
        {{- '<|im_start|>' + message.role + '\n' + message.content + '<|im_end|>' + '\n' }}
    {%- elif message.role == "assistant" %}
        {%- set content = message.content %}
        {%- set reasoning_content = '' %}
        {%- if message.reasoning_content is defined and message.reasoning_content is not none %}
            {%- set reasoning_content = message.reasoning_content %}
        {%- else %}
            {%- if '</think>' in message.content %}
                {%- set content = (message.content.split('</think>')|last).lstrip('\n') %}
        {%- set reasoning_content = (message.content.split('</think>')|first).rstrip('\n') %}
        {%- set reasoning_content = (reasoning_content.split('<think>')|last).lstrip('\n') %}
            {%- endif %}
        {%- endif %}
        {%- if loop.index0 > ns.last_query_index %}
            {%- if loop.last or (not loop.last and reasoning_content) %}
                {{- '<|im_start|>' + message.role + '\n<think>\n' + reasoning_content.strip('\n') + '\n</think>\n\n' + content.lstrip('\n') }}
            {%- else %}
                {{- '<|im_start|>' + message.role + '\n' + content }}
            {%- endif %}
        {%- else %}
            {{- '<|im_start|>' + message.role + '\n' + content }}
        {%- endif %}
        {%- if message.tool_calls %}
            {%- for tool_call in message.tool_calls %}
                {%- if (loop.first and content) or (not loop.first) %}
                    {{- '\n' }}
                {%- endif %}
                {%- if tool_call.function %}
                    {%- set tool_call = tool_call.function %}
                {%- endif %}
                {{- '<tool_call>\n{"name": "' }}
                {{- tool_call.name }}
                {{- '", "arguments": ' }}
                {%- if tool_call.arguments is string %}
                    {{- tool_call.arguments }}
                {%- else %}
                    {{- tool_call.arguments | tojson }}
                {%- endif %}
                {{- '}\n</tool_call>' }}
            {%- endfor %}
        {%- endif %}
        {{- '<|im_end|>\n' }}
    {%- elif message.role == "tool" %}
        {%- if loop.first or (messages[loop.index0 - 1].role != "tool") %}
            {{- '<|im_start|>user' }}
        {%- endif %}
        {{- '\n<tool_response>\n' }}
        {{- message.content }}
        {{- '\n</tool_response>' }}
        {%- if loop.last or (messages[loop.index0 + 1].role != "tool") %}
            {{- '<|im_end|>\n' }}
        {%- endif %}
    {%- endif %}
{%- endfor %}
{%- if add_generation_prompt %}
    {{- '<|im_start|>assistant\n' }}
    {%- if enable_thinking is defined and enable_thinking is false %}
        {{- '<think>\n\n</think>\n\n' }}
    {%- endif %}
{%- endif %}
```
