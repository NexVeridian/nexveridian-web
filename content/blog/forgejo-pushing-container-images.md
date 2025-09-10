+++
title = "Pushing container images in Forgejo actions"
date = 2025-08-27

[taxonomies]
tags = ["forgejo", "nix", "CI", "actions", "docker"]
+++

## Pushing container images
With GitHub actions most people use `docker push` to push their images to a registry.

With Forgejo actions, that probably won't work. because of docker-in-docker. Instead, you can use the `skopeo` to push your images to a registry.

To Setup `CONTAINER_TOKEN`:
- create a token https://git.example.com/user/settings/applications
- then add the token to your secrets https://forgejo.example.com/user/settings/actions/secrets

### Note:
Forgejo create a [Automatic token](https://forgejo.org/docs/latest/user/actions/basic-concepts/#automatic-token) with each workflow run.

But you can't use it to push images to a registry.

```yaml
name: docker

on:
  push:
    branches: [main]

env:
  REGISTRY: git.nexveridian.com
  IMAGE_NAME: ${{ github.repository }}
  NIX_CONFIG: "experimental-features = nix-command flakes"
  CONTAINER_TOKEN: ${{ secrets.CONTAINER_REGISTRY_TOKEN }}

jobs:
  build:
    runs-on: nix
    permissions:
      contents: read
      packages: write
      id-token: write

    steps:
      - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client login nex https://nix.example.com ${{ secrets.ATTIC_TOKEN }} || true
      - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client cache create <cache name> || true
      - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client cache configure <cache name> -- --priority 30 || true
      - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client use <cache name> || true

      - name: Install Node.js
        run: |
          mkdir -p ~/.local/bin
          nix build -I nixpkgs=channel:nixos-unstable nixpkgs#nodejs_24 -o ~/.local/nodejs
          ln -sf ~/.local/nodejs/bin/node ~/.local/bin/node
          ln -sf ~/.local/nodejs/bin/npm ~/.local/bin/npm
          echo "$HOME/.local/bin" >> $GITHUB_PATH

      - uses: actions/checkout@v4

      - name: Install skopeo
        run: |
          mkdir -p ~/.local/bin
          nix build -I nixpkgs=channel:nixos-unstable nixpkgs#skopeo -o ~/.local/skopeo
          ln -sf ~/.local/skopeo/bin/skopeo ~/.local/bin/skopeo
          echo "$HOME/.local/bin" >> $GITHUB_PATH

      - name: Build Nix package
        run: nix build .#my-docker

      - name: Prepare repository variables
        run: |
          echo "REPO=${GITHUB_REPOSITORY,,}" >> ${GITHUB_ENV}
          echo "OWNER=${GITHUB_REPOSITORY_OWNER,,}" >> ${GITHUB_ENV}
          # Extract just the repository name (everything after the last slash)
          REPO_NAME=${GITHUB_REPOSITORY##*/}
          echo "IMAGE_NAME=${REPO_NAME,,}" >> ${GITHUB_ENV}

      - name: Setup skopeo policy and push image
        run: |
          # configure container policy to accept insecure registry
          mkdir -p ~/.config/containers
          cat > ~/.config/containers/policy.json <<EOF
          {
            "default": [{"type":"insecureAcceptAnything"}]
          }
          EOF

          # ensure all required directories exist with proper permissions
          mkdir -p /tmp/skopeo /var/tmp ~/.local/share/containers
          chmod 755 /tmp/skopeo /var/tmp || true

          # set multiple environment variables for skopeo temporary directories
          export TMPDIR=/tmp/skopeo
          export TMP=/tmp/skopeo
          export TEMP=/tmp/skopeo
          export XDG_RUNTIME_DIR=/tmp/skopeo

          # The Nix build creates a compressed tar.gz file, we need to extract it first
          cd /tmp/skopeo
          cp ${GITHUB_WORKSPACE}/result ./docker-image.tar.gz
          gunzip docker-image.tar.gz

          # Create authentication file for skopeo
          mkdir -p ~/.docker
          cat > ~/.docker/config.json <<EOF
          {
            "auths": {
              "${{ env.REGISTRY }}": {
                "auth": "$(echo -n "${{ github.actor }}:${{ env.CONTAINER_TOKEN }}" | base64 -w 0)"
              }
            }
          }
          EOF

          # Also create auth for containers directory
          mkdir -p ~/.config/containers
          cp ~/.docker/config.json ~/.config/containers/auth.json

          # Test registry connectivity
          skopeo login --username "${{ github.actor }}" --password "${{ env.CONTAINER_TOKEN }}" "${{ env.REGISTRY }}"

          # Push image using Personal Access Token
          skopeo copy \
            --dest-tls-verify=false \
            --tmpdir /tmp/skopeo \
            --dest-creds "${{ github.actor }}:${{ env.CONTAINER_TOKEN }}" \
            docker-archive:/tmp/skopeo/docker-image.tar \
            docker://${{ env.REGISTRY }}/${{ env.OWNER }}/${{ env.IMAGE_NAME }}:latest

      - name: Push to attic
        if: always()
        run: |
          nix shell nixpkgs/nixos-unstable#findutils nixpkgs/nixos-unstable#util-linux nixpkgs/nixos-unstable#coreutils -c bash -c '
            valid_paths=$(find /nix/store -maxdepth 1 -type d -name "*-*" | \
              head -1000 | \
              xargs -I {} -P $(nproc) sh -c "nix path-info \"\$1\" >/dev/null 2>&1 && echo \"\$1\"" _ {} | \
              tr "\n" " ")

            if [ -n "$valid_paths" ]; then
              for i in {1..10}; do
                nix run nixpkgs/nixos-unstable#attic-client push <cache name> $valid_paths && break || [ $i -eq 10 ] || sleep 5
              done
            fi
          '
```
