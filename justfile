run:
    zola serve

update:
    nix flake update

watch:
    typst watch Elijah_McMorris_Resume.typ

watch2:
    typst watch Elijah_McMorris_Resume_.typ

pdf:
    typst compile Elijah_McMorris_Resume.typ
    typst compile Elijah_McMorris_Resume_.typ
    typstyle -i --wrap-text -l 100 Elijah_McMorris_Resume.typ
    typstyle -i --wrap-text -l 100 Elijah_McMorris_Resume_.typ

    mv Elijah_McMorris_Resume.pdf static/
    typst compile Elijah_McMorris_Resume.typ
    mv Elijah_McMorris_Resume.pdf /Users/elijahmcmorris/Desktop/Stuff/Excel/

    mv Elijah_McMorris_Resume_.pdf /Users/elijahmcmorris/Desktop/Stuff/Excel/

    typst compile Elijah_McMorris_Resume.typ
    typst compile Elijah_McMorris_Resume_.typ

docker:
    nix build .#packages.x86_64-linux.my-docker
    docker load < ./result
    docker rm -f nexveridian-web
    docker run -d --rm -p 80:80 --name nexveridian-web nexveridian-web:latest
    rm -rf result
    docker image prune -f

uv:
    uv venv --clear
    just uv_install
    uv run hf auth login

uv_install:
    # uv pip install -U huggingface_hub hf_transfer mlx_lm "mlx_lm[train]" tiktoken blobfile
    uv pip install -U huggingface_hub hf_transfer "git+https://github.com/ml-explore/mlx-lm@main" "git+https://github.com/ml-explore/mlx-lm@main[train]" tiktoken blobfile

# just mlx_create "cerebras/GLM-4.7-Flash-REAP-23B-A3B" "3 4 5 6 8" "/Users/elijahmcmorris/.cache/lm-studio/models" NexVeridian true false

# just mlx_create "Qwen/Qwen3-Coder-Next" "4" "/Users/elijahmcmorris/.cache/lm-studio/models" NexVeridian false false
mlx_create hf_url quant lm_studio_path org="mlx-community" upload_repo="false" clean="true":
    #!/usr/bin/env bash
    just uv_install
    repo_name=$(basename {{ hf_url }})
    just clean_lmstudio "{{ hf_url }}" "{{ quant }}" "{{ lm_studio_path }}" "{{ org }}"

    for q in {{ quant }}; do
        rm {{ lm_studio_path }}/{{ org }}/${repo_name}-${q}bit

        echo -e '\nConverting {{ hf_url }} to '"$q"'-bit quantization\n'
        if [[ {{ upload_repo }} == "true" ]]; then
            uv run mlx_lm.convert \
                --hf-path {{ hf_url }} \
                -q \
                --q-bits ${q} \
                --trust-remote-code \
                --upload-repo {{ org }}/${repo_name}-${q}bit \
                --mlx-path {{ lm_studio_path }}/{{ org }}/${repo_name}-${q}bit
        else
            uv run mlx_lm.convert \
                --hf-path {{ hf_url }} \
                -q \
                --q-bits ${q} \
                --trust-remote-code \
                --mlx-path {{ lm_studio_path }}/{{ org }}/${repo_name}-${q}bit
        fi

        if [[ {{ clean }} == "true" ]]; then
            just clean_lmstudio "{{ hf_url }}" "{{ quant }}" "{{ lm_studio_path }}" "{{ org }}"
        fi
    done

# just mlx_create_dynamic "cerebras/Qwen3-Coder-REAP-25B-A3B" 4 8 "/Users/elijahmcmorris/.cache/lm-studio/models" NexVeridian true false
# https://github.com/ml-explore/mlx-lm/blob/main/mlx_lm/LEARNED_QUANTS.md

# https://github.com/ml-explore/mlx-lm/blob/main/mlx_lm/quant/dynamic_quant.py
mlx_create_dynamic hf_url low high lm_studio_path org="mlx-community" upload_repo="false" clean="true":
    #!/usr/bin/env bash
    just uv_install
    repo_name=$(basename {{ hf_url }})
    rm -r {{ lm_studio_path }}/{{ org }}/${repo_name} || true

    org_name=$(echo "{{ hf_url }}" | cut -d'/' -f1)
    sanitized_name="${org_name}_$(basename {{ hf_url }})"
    sensitivity_file="sensitivities/${sanitized_name}_sensitivities.json"

    if [[ -f "$sensitivity_file" ]]; then
        uv run mlx_lm.dynamic_quant \
            --model {{ hf_url }} \
            --low-bits {{ low }} \
            --high-bits {{ high }} \
            --accumulation-dtype bfloat16 \
            --sensitivities "$sensitivity_file" \
            --mlx-path {{ lm_studio_path }}/{{ org }}/${repo_name}
    else
        uv run mlx_lm.dynamic_quant \
            --model {{ hf_url }} \
            --low-bits {{ low }} \
            --high-bits {{ high }} \
            --accumulation-dtype bfloat16 \
            --mlx-path {{ lm_studio_path }}/{{ org }}/${repo_name}
    fi

    if [[ -f "${sanitized_name}_sensitivities.json" ]]; then
        mv "${sanitized_name}_sensitivities.json" "$sensitivity_file"
        echo "Saved sensitivities to $sensitivity_file"
    fi

    if [[ {{ upload_repo }} == "true" ]]; then
        uv run mlx_lm.upload \
            --path {{ lm_studio_path }}/{{ org }}/${repo_name} \
            --upload-repo {{ org }}/${repo_name}-{{ low }}bit-{{ high }}bit
    fi

    if [[ {{ clean }} == "true" ]]; then
        rm -r {{ lm_studio_path }}/{{ org }}/${repo_name} || true
    fi

# just mlx_create_dwq "cerebras/Qwen3-Coder-REAP-25B-A3B" "5" "8" "128" "/Users/elijahmcmorris/.cache/lm-studio/models" NexVeridian true false
# https://github.com/ml-explore/mlx-lm/blob/main/mlx_lm/LEARNED_QUANTS.md

# https://github.com/ml-explore/mlx-lm/blob/main/mlx_lm/quant/dwq.py
mlx_create_dwq hf_url quant teacher_q samples lm_studio_path org="mlx-community" upload_repo="false" clean="true":
    #!/usr/bin/env bash
    just uv_install
    repo_name=$(basename {{ hf_url }})

    if [[ "{{ teacher_q }}" == "16" ]]; then
        for q in {{ quant }}; do
            echo -e '\nConverting {{ hf_url }} to '"$q"'-bit DWQ quantization\n'
            just clean_lmstudio "{{ hf_url }}" "{{ quant }}" "{{ lm_studio_path }}" "{{ org }}" "-DWQ"

            uv run mlx_lm.dwq \
                --model {{ hf_url }} \
                --bits ${q} \
                --num-samples {{ samples }} \
                --batch-size 1 \
                --max-seq-length 512 \
                --mlx-path {{ lm_studio_path }}/{{ org }}/${repo_name}-${q}bit-DWQ

            if [[ {{ upload_repo }} == "true" ]]; then
                uv run mlx_lm.upload \
                    --path {{ lm_studio_path }}/{{ org }}/${repo_name}-${q}bit-DWQ \
                    --upload-repo {{ org }}/${repo_name}-${q}bit-DWQ
            fi

            if [[ {{ clean }} == "true" ]]; then
                just clean_lmstudio "{{ hf_url }}" "{{ quant }}" "{{ lm_studio_path }}" "{{ org }}" "-DWQ"
            fi
        done
    else
        for q in {{ quant }}; do
            echo -e '\nConverting {{ hf_url }} to '"$q"'-bit DWQ quantization, with teacher_q = {{ teacher_q }}\n'
            just clean_lmstudio "{{ hf_url }}" "{{ quant }}" "{{ lm_studio_path }}" "{{ org }}" "-DWQ-{{ teacher_q }}bit"

            just mlx_create "{{ hf_url }}" "{{ teacher_q }}" "/Users/elijahmcmorris/.cache/lm-studio/models" NexVeridian false true

            uv run mlx_lm.dwq \
                --model {{ hf_url }} \
                --quantized-model {{ org }}/${repo_name}-{{ teacher_q }}bit \
                --bits ${q} \
                --num-samples {{ samples }} \
                --batch-size 1 \
                --max-seq-length 512 \
                --mlx-path {{ lm_studio_path }}/{{ org }}/${repo_name}-${q}bit-DWQ-{{ teacher_q }}bit

            if [[ {{ upload_repo }} == "true" ]]; then
                uv run mlx_lm.upload \
                    --path {{ lm_studio_path }}/{{ org }}/${repo_name}-${q}bit-DWQ-{{ teacher_q }}bit \
                    --upload-repo {{ org }}/${repo_name}-${q}bit-DWQ-{{ teacher_q }}bit
            fi

            if [[ {{ clean }} == "true" ]]; then
                just clean_lmstudio "{{ hf_url }}" "{{ quant }}" "{{ lm_studio_path }}" "{{ org }}" "-DWQ-{{ teacher_q }}bit"
            fi
        done
    fi

clean_hf:
    rm -r ~/.cache/huggingface/hub/*

# just clean_lmstudio "Qwen/QwQ-32B" "4 6 8" "/Users/elijahmcmorris/.cache/lm-studio/models" NexVeridian "-DWQ"
clean_lmstudio hf_url quant lm_studio_path org="mlx-community" type="":
    #!/usr/bin/env bash
    repo_name=$(basename {{ hf_url }})

    for q in {{ quant }}; do
        rm -r {{ lm_studio_path }}/{{ org }}/${repo_name}-${q}bit{{ type }} || true
    done

process_single_model hf_url rclone="false" clean="true":
    #!/usr/bin/env bash
    export HF_HUB_CACHE="/Volumes/hf-cache/huggingface/hub"
    # Store original HF_HUB_CACHE
    ORIGINAL_HF_HUB_CACHE="${HF_HUB_CACHE:-}"

    model="{{ hf_url }}"
    echo "Processing model: $model"

    # Convert model path to cache directory format (org--model)
    model_cache_name=$(echo "$model" | sed 's/\//--/g' | sed 's/^/models--/')

    echo "Copying $model_cache_name from NAS..."
    rclone copyto -P --fast-list --links --transfers 4 --multi-thread-streams 32 \
        --exclude "tower:hf-cache/huggingface/hub/$model_cache_name/snapshots" \
        "tower:hf-cache/huggingface/hub/$model_cache_name" \
        "$HOME/.cache/huggingface/hub/$model_cache_name"

    # Set HF_HUB_CACHE to local cache
    export HF_HUB_CACHE="$HOME/.cache/huggingface/hub"

    echo "Processing quantizations for $model..."
    just mlx_create "$model" "3 4 5 6 8" "/Users/elijahmcmorris/.cache/lm-studio/models" NexVeridian true true
    # just mlx_create_dynamic "$model" 5 8 "/Users/elijahmcmorris/.cache/lm-studio/models" NexVeridian true true
    # just mlx_create_dynamic "$model" 4 8 "/Users/elijahmcmorris/.cache/lm-studio/models" NexVeridian true true
    # just mlx_create_dwq "$model" "5 4" "16" "2048" "/Users/elijahmcmorris/.cache/lm-studio/models" NexVeridian true true

    if [[ {{ rclone }} == "true" ]]; then
        rclone sync -P --fast-list --links --transfers 4 --multi-thread-streams 32 \
            --exclude "$HOME/.cache/huggingface/hub/$model_cache_name/snapshots" \
            "$HOME/.cache/huggingface/hub/$model_cache_name" \
            "tower:hf-cache/huggingface/hub/$model_cache_name"
    fi

    if [[ {{ clean }} == "true" ]]; then
        echo "Cleaning up local cache for $model..."
        rm -rf "$HOME/.cache/huggingface/hub/$model_cache_name"
    fi

    # Reset HF_HUB_CACHE to original value
    if [[ -n "$ORIGINAL_HF_HUB_CACHE" ]]; then
        export HF_HUB_CACHE="$ORIGINAL_HF_HUB_CACHE"
    else
        unset HF_HUB_CACHE
    fi

    echo "Completed processing $model"

create_all clean="true":
    #!/usr/bin/env bash
    # List of models to process
    models=(
        # zai-org/GLM-4.7-Flash
        # cerebras/GLM-4.7-Flash-REAP-23B-A3B
        # cerebras/Qwen3-Coder-REAP-25B-A3B
        # Qwen/Qwen3-Coder-Next
        cerebras/Kimi-Linear-REAP-35B-A3B-Instruct
    )
    for model in "${models[@]}"; do
        echo "Processing model: $model"
        just process_single_model "$model" {{ clean }}
    done

    if [[ {{ clean }} == "true" ]]; then
        just clean_hf || true
    fi
