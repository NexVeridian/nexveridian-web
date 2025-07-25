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
    uv pip install -U huggingface_hub hf_transfer mlx_lm "mlx_lm[train]" tiktoken
    # uv pip install -U huggingface_hub hf_transfer "git+https://github.com/ml-explore/mlx-lm@main" "git+https://github.com/ml-explore/mlx-lm@main[train]"

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

# just mlx_create_dynamic "Qwen/Qwen3-14B" 4 8 "/Users/elijahmcmorris/.cache/lm-studio/models" NexVeridian true false
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
