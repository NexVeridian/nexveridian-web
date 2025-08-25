run:
    zola serve

update:
    nix flake update

docker:
    nix build .#packages.x86_64-linux.my-docker
    docker load < ./result
    docker rm -f nexveridian-web
    docker run -d --rm -p 80:80 --name nexveridian-web nexveridian-web:latest
    rm -rf result
    docker image prune -f

uv:
    uv venv
    just uv_install
    uv run hf auth login

uv_install:
    # uv pip install -U huggingface_hub hf_transfer mlx_lm "mlx_lm[train]" tiktoken blobfile
    uv pip install -U huggingface_hub hf_transfer "git+https://github.com/ml-explore/mlx-lm@main" "git+https://github.com/ml-explore/mlx-lm@main[train]" tiktoken blobfile

# just mlx_create "Qwen/Qwen3-30B-A3B" "3 4 5 6 8" "/Users/elijahmcmorris/.cache/lm-studio/models" NexVeridian true true
mlx_create hf_url quant lm_studio_path org="mlx-community" upload_repo="false" clean="true":
    #!/usr/bin/env bash
    just uv_install
    repo_name=$(basename {{hf_url}})
    just clean_lmstudio "{{hf_url}}" "{{quant}}" "{{lm_studio_path}}" "{{org}}"

    for q in {{quant}}; do
        rm {{lm_studio_path}}/{{org}}/${repo_name}-${q}bit

        echo -e '\nConverting {{hf_url}} to '"$q"'-bit quantization\n'
        if [[ {{upload_repo}} == "true" ]]; then
            uv run mlx_lm.convert \
                --hf-path {{hf_url}} \
                -q \
                --q-bits ${q} \
                --trust-remote-code \
                --upload-repo {{org}}/${repo_name}-${q}bit \
                --mlx-path {{lm_studio_path}}/{{org}}/${repo_name}-${q}bit
        else
            uv run mlx_lm.convert \
                --hf-path {{hf_url}} \
                -q \
                --q-bits ${q} \
                --trust-remote-code \
                --mlx-path {{lm_studio_path}}/{{org}}/${repo_name}-${q}bit
        fi

        if [[ {{clean}} == "true" ]]; then
            just clean_lmstudio "{{hf_url}}" "{{quant}}" "{{lm_studio_path}}" "{{org}}"
        fi
    done

# just mlx_create_dynamic "Qwen/Qwen3-14B" 5 8 "/Users/elijahmcmorris/.cache/lm-studio/models" NexVeridian true false
# https://github.com/ml-explore/mlx-lm/blob/main/mlx_lm/LEARNED_QUANTS.md
mlx_create_dynamic hf_url low high lm_studio_path org="mlx-community" upload_repo="false" clean="true":
    #!/usr/bin/env bash
    just uv_install
    repo_name=$(basename {{hf_url}})
    rm -r {{lm_studio_path}}/{{org}}/${repo_name}-{{low}}bit-{{high}}bit || true

    uv run mlx_lm.dynamic_quant \
        --model {{hf_url}} \
        --low-bits {{low}} \
        --high-bits {{high}} \
        --mlx-path {{lm_studio_path}}/{{org}}/${repo_name}-{{low}}bit-{{high}}bit

    if [[ {{upload_repo}} == "true" ]]; then
        uv run mlx_lm.upload \
            --path {{lm_studio_path}}/{{org}}/${repo_name}-{{low}}bit-{{high}}bit \
            --upload-repo {{org}}/${repo_name}-{{low}}bit-{{high}}bit
    fi

    if [[ {{clean}} == "true" ]]; then
        rm -r {{lm_studio_path}}/{{org}}/${repo_name}-{{low}}bit-{{high}}bit || true
    fi


# just mlx_create_dwq "Qwen/Qwen3-30B-A3B" "4" "/Users/elijahmcmorris/.cache/lm-studio/models" NexVeridian true false
# https://github.com/ml-explore/mlx-lm/blob/main/mlx_lm/LEARNED_QUANTS.md
# https://github.com/ml-explore/mlx-lm/blob/main/mlx_lm/quant/dwq.py
mlx_create_dwq hf_url quant lm_studio_path org="mlx-community" upload_repo="false" clean="true":
    #!/usr/bin/env bash
    just uv_install
    repo_name=$(basename {{hf_url}})
    teacher_q="8"
    just clean_lmstudio "{{hf_url}}" "{{quant}}" "{{lm_studio_path}}" "{{org}}" "-DWQ-${teacher_q}bit"

    for q in {{quant}}; do
        rm {{lm_studio_path}}/{{org}}/${repo_name}-${q}bit-DWQ

        echo -e '\nConverting {{hf_url}} to '"$q"'-bit DWQ quantization\n'
        uv run mlx_lm.dwq \
            --model {{hf_url}} \
            --quantized-model {{org}}/${repo_name}-${teacher_q}bit \
            --bits ${q} \
            --group-size 32 \
            --num-samples 512 \
            --batch-size 1 \
            --max-seq-length 512 \
            --mlx-path {{lm_studio_path}}/{{org}}/${repo_name}-${q}bit-DWQ-${teacher_q}bit

        if [[ {{upload_repo}} == "true" ]]; then
            uv run mlx_lm.upload \
                --path {{lm_studio_path}}/{{org}}/${repo_name}-${q}bit-DWQ-${teacher_q}bit \
                --upload-repo {{org}}/${repo_name}-${q}bit-DWQ-${teacher_q}bit
        fi

        if [[ {{clean}} == "true" ]]; then
            just clean_lmstudio "{{hf_url}}" "{{quant}}" "{{lm_studio_path}}" "{{org}}" "-DWQ-${teacher_q}bit"
        fi
    done

clean_hf:
    rm -r ~/.cache/huggingface/hub/*

# just clean_lmstudio "Qwen/QwQ-32B" "4 6 8" "/Users/elijahmcmorris/.cache/lm-studio/models" NexVeridian "-DWQ"
clean_lmstudio hf_url quant lm_studio_path org="mlx-community" type="":
    #!/usr/bin/env bash
    repo_name=$(basename {{hf_url}})

    for q in {{quant}}; do
        rm -r {{lm_studio_path}}/{{org}}/${repo_name}-${q}bit{{type}} || true
    done

process_single_model hf_url:
    #!/usr/bin/env bash
    export HF_HUB_CACHE="/Volumes/hf-cache/huggingface/hub"
    # Store original HF_HUB_CACHE
    ORIGINAL_HF_HUB_CACHE="${HF_HUB_CACHE:-}"

    model="{{hf_url}}"
    echo "Processing model: $model"

    # Convert model path to cache directory format (org--model)
    model_cache_name=$(echo "$model" | sed 's/\//--/g' | sed 's/^/models--/')

    echo "Copying $model_cache_name from NAS..."
    rclone copyto -P --fast-list --copy-links --transfers 32 --multi-thread-streams 32 \
        "tower:hf-cache/huggingface/hub/$model_cache_name" \
        "$HOME/.cache/huggingface/hub/$model_cache_name"

    # Set HF_HUB_CACHE to local cache
    export HF_HUB_CACHE="$HOME/.cache/huggingface/hub"

    echo "Processing quantizations for $model..."
    just mlx_create "$model" "3 4 5 6 8" "/Users/elijahmcmorris/.cache/lm-studio/models" NexVeridian true true

    rclone copyto -P --fast-list --copy-links --transfers 32 --multi-thread-streams 32 \
        "$HOME/.cache/huggingface/hub/$model_cache_name" \
        "tower:hf-cache/huggingface/hub/$model_cache_name"

    # Clean up local model cache
    echo "Cleaning up local cache for $model..."
    # rm -rf "$HOME/.cache/huggingface/hub/$model_cache_name"
    just clean_hf || true

    # Reset HF_HUB_CACHE to original value
    if [[ -n "$ORIGINAL_HF_HUB_CACHE" ]]; then
        export HF_HUB_CACHE="$ORIGINAL_HF_HUB_CACHE"
    else
        unset HF_HUB_CACHE
    fi

    echo "Completed processing $model"

create_all:
    #!/usr/bin/env bash
    # List of models to process
    models=(
        # Qwen/Qwen3-30B-A3B-Instruct-2507
        # Qwen/Qwen3-30B-A3B-Thinking-2507
        # "Qwen/Qwen3-Coder-30B-A3B-Instruct"
        # "Qwen/Qwen3-Coder-480B-A35B-Instruct"
        # "openai/gpt-oss-20b"
        # "openai/gpt-oss-120b"
        # janhq/Jan-v1-4B
        # moonshotai/Kimi-VL-A3B-Thinking-2506
        # nvidia/OpenReasoning-Nemotron-1.5B
        # nvidia/OpenReasoning-Nemotron-7B
        # nvidia/OpenReasoning-Nemotron-14B
        # nvidia/OpenReasoning-Nemotron-32B
        # ByteDance-Seed/Seed-OSS-36B-Instruct
    )

    for model in "${models[@]}"; do
        echo "Processing model: $model"
        just process_single_model "$model"
    done
