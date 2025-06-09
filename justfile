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

# just mlx_create "Qwen/QwQ-32B" "4 6 8" "/Users/elijahmcmorris/.cache/lm-studio/models" "false"
mlx_create hf_url quant lm_studio_path upload_repo="false":
    #!/usr/bin/env bash
    just clean_lmstudio "{{hf_url}}" "{{quant}}" "{{lm_studio_path}}"

    for q in {{quant}}; do
        echo -e '\nConverting {{hf_url}} to '"$q"'-bit quantization\n'
        repo_name=$(basename {{hf_url}})
        rm {{lm_studio_path}}/mlx-community/${repo_name}-${q}bit

        if [[ {{upload_repo}} == "true" ]]; then
            uv run mlx_lm.convert \
                --hf-path {{hf_url}} \
                -q \
                --q-bits ${q} \
                --upload-repo mlx-community/${repo_name}-${q}bit \
                --mlx-path {{lm_studio_path}}/mlx-community/${repo_name}-${q}bit
        else
            uv run mlx_lm.convert \
                --hf-path {{hf_url}} \
                -q \
                --q-bits ${q} \
                --mlx-path {{lm_studio_path}}/mlx-community/${repo_name}-${q}bit
        fi
    done

    just clean_lmstudio "{{hf_url}}" "{{quant}}" "{{lm_studio_path}}"


clean_hf:
    rm -r ~/.cache/huggingface/hub/*

# just clean_lmstudio "Qwen/QwQ-32B" "4 6 8" "/Users/elijahmcmorris/.cache/lm-studio/models"
clean_lmstudio hf_url quant lm_studio_path:
    #!/usr/bin/env bash
    repo_name=$(basename {{hf_url}})
    for q in {{quant}}; do
        rm -r {{lm_studio_path}}/mlx-community/${repo_name}-${q}bit || true
    done
