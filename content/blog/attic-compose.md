+++
title = "Deploying `Attic` Nix Binary Cache With Docker Compose, for local use and CI"
date = 2025-05-06
# description = "Deploying Attic Nix Binary Cache With Docker Compose."

[taxonomies]
tags = ["nix", "docker", "CI", "actions", "cache", "github-actions"]
+++

## Server Install
Install docker and docker compose

### Example `docker-compose.yaml`
```yaml
services:
  attic:
    container_name: attic
    image: ghcr.io/zhaofengli/attic:latest
    command: ["-f", "/attic/server.toml"]
    restart: unless-stopped
    ports:
      - 8080:8080
    networks:
      attic:
      pgattic:
    volumes:
      - ./server.toml:/attic/server.toml
      - attic-data:/attic/storage
    env_file:
      - prod.env
    depends_on:
      pgattic:
          condition: service_healthy
    healthcheck:
        test:
            [
                "CMD-SHELL",
                "wget --no-verbose --tries=1 --spider http://attic:8080 || exit 1",
            ]
        interval: 15s
        timeout: 10s
        retries: 10
        start_period: 15s
    deploy:
        resources:
            reservations:
                cpus: 1.0

  pgattic:
    container_name: pgattic
    image: postgres:17.6-alpine
    restart: unless-stopped
    ports:
      - 5432:5432
    networks:
      pgattic:
    volumes:
      - postgres-data:/var/lib/postgresql/data
    env_file:
      - prod.env
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  attic-data:
  postgres-data:

networks:
  attic:
  pgattic:
```

### Example `server.toml`
```toml
listen = "[::]:8080"

[database]
url = "postgres://attic:attic@pgattic:5432/attic_prod"

[storage]
type = "local"
path = "/attic/storage"

[chunking]
nar-size-threshold = 65536
min-size = 16384
avg-size = 65536
max-size = 262144

[compression]
type = "zstd"

[garbage-collection]
interval = "12 hours"
```

### Example `prod.env`
```bash
POSTGRES_DB=attic_prod
POSTGRES_USER=attic
POSTGRES_PASSWORD=attic
DATABASE_URL=postgres://attic:attic@localhost:5432/attic_prod
ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64="<openssl rand 64 | base64 -w0>"
```

### Exmaple Traefik Label
```yaml
traefik:
  # ...
  command:
    # ...
    - "--entrypoints.websecure.transport.respondingTimeouts.readTimeout=0s"

attic:
  # ...
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.attic.rule=Host(`nix.example.com`)"
    - "traefik.http.routers.attic.entrypoints=websecure"
    - "traefik.http.routers.attic.tls.certresolver=myhttpchallenge"

    - "traefik.http.routers.attic-http.rule=Host(`nix.example.com`)"
    - "traefik.http.routers.attic-http.entrypoints=web"
    - "traefik.http.routers.attic-http.service=attic"

    - "traefik.http.services.attic.loadbalancer.server.port=8080"
    - "traefik.docker.network=<network name>"
```

### Cloudflare
If you are using cloudflare make the subdomain DNS only

### Create the Token
```bash
docker compose up

docker exec -it attic sh -c 'atticadm make-token --sub "{{<your username here>}}" --validity "10y" --pull "*" --push "*" --create-cache "*" --configure-cache "*" --configure-cache-retention "*" --destroy-cache "*" --delete "*" -f "./attic/server.toml"'
```

### Check if it works
If working `nix.example.com` should say `attic push`

## Client Install
Install `pkg.attic-client`

make sure your user is trusted
```nix
nix.settings = {
  trusted-users = [
    "root"
    "<your username here>"
  ];
};
```

```bash
# then login to attic
attic login <pick a name for server> https://nix.example.com <token from just create_token>

# create a cache to push to
attic cache create <cache name>

# use the cache
attic use <cache name>

# pushing to the cache
attic push <cache name> /nix/store/*/
```

## Github Actions Install
Add the token named from `just create_token`, named ATTIC_TOKEN, to your repository secrets `https://github.com/<username>/<repo>/settings/secrets/actions`
```yaml
name: nix

on:
  pull_request:
    branches: [main]
  push:
  schedule:
    - cron: 0 0 * * 1

concurrency:
  group: ${{ github.workflow }}-${{ github.head_ref && github.ref || github.run_id }}
  cancel-in-progress: true

env:
  CARGO_TERM_COLOR: always

steps:
  - uses: actions/checkout@v3
  - uses: nixbuild/nix-quick-install-action@v32
    with:
      nix_conf: |
        keep-env-derivations = true
        keep-outputs = true

  # For cacheing the attic package in github actions storage
  - name: Restore Nix store cache
    id: cache-nix-restore
    uses: nix-community/cache-nix-action/restore@v6
    with:
      primary-key: nix-${{ runner.os }}-${{ hashFiles('**/*.nix', '**/flake.lock') }}
      restore-prefixes-first-match: nix-${{ runner.os }}-

  - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client login <pick a name for server> https://nix.example.com ${{ secrets.ATTIC_TOKEN }} || true
  - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client cache create <cache name> || true
  - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client cache configure <cache name> -- --priority 30 || true
  - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client use <cache name> || true

  # For cacheing the attic package in github actions storage
  - run: nix build -I nixpkgs=channel:nixos-unstable nixpkgs#nix-fast-build
  - name: Save Nix store cache
    id: cache-nix-save
    uses: nix-community/cache-nix-action/save@v6
    with:
      primary-key: nix-${{ runner.os }}-${{ hashFiles('**/*.nix', '**/flake.lock') }}
      gc-max-store-size-linux: 2G
      purge: true
      purge-prefixes: nix-${{ runner.os }}-
      purge-created: 0
      purge-last-accessed: 0
      purge-primary-key: never

  # `nix-fast-build` is faster then `nix flake check` in my testing
  # - name: check
  #   run: |
  #     nix flake check --all-systems

  # `--attic-cache` will fail if the cache is down
  # - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#nix-fast-build -- --attic-cache <cache name> --no-nom --skip-cached
  - name: check
    run: |
      nix run -I nixpkgs=channel:nixos-unstable nixpkgs#nix-fast-build -- --no-nom --skip-cached

  # Paths will be invalid if tests fail, need to push all other paths
  - name: Push to attic
    if: always()
    run: |
      valid_paths=""
      for path in /nix/store/*/; do
        if nix path-info "$path" >/dev/null 2>&1; then
          valid_paths="$valid_paths $path"
        fi
      done

      if [ -n "$valid_paths" ]; then
        for i in {1..10}; do
          nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client push <cache name> $valid_paths && break || [ $i -eq 5 ] || sleep 5
        done
      fi
```

## Github Action Install, with matrix for each derivation
```yaml
name: crane

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  schedule:
    - cron: 0 0 * * 1

concurrency:
  group: ${{ github.workflow }}-${{ github.head_ref && github.ref || github.run_id }}
  cancel-in-progress: true

env:
  CARGO_TERM_COLOR: always

jobs:
  check-dependencies:
    name: check-dependencies
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
      actions: write

    strategy:
      matrix:
        system: [x86_64-linux]
        check-type: [my-server, my-crate-fmt, my-crate-toml-fmt]

    steps:
      - uses: actions/checkout@v5
      - uses: nixbuild/nix-quick-install-action@v32
        with:
          nix_conf: |
            keep-env-derivations = true
            keep-outputs = true

      - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client login nex https://nix.example.com ${{ secrets.ATTIC_TOKEN }} || true
      - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client cache create <cache name> || true
      - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client cache configure <cache name> -- --priority 30 || true
      - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client use <cache name> || true

      - run: nix build -I nixpkgs=channel:nixos-unstable nixpkgs#nix-fast-build

      - name: check
        run: |
          nix run -I nixpkgs=channel:nixos-unstable nixpkgs#nix-fast-build -- --flake ".#checks.$(nix eval --raw --impure --expr builtins.currentSystem).${{ matrix.check-type }}" --no-nom --skip-cached

      - name: Push to attic
        if: always()
        run: |
          for i in {1..10}; do
            nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client push <cache name> /nix/store/*/ && break || [ $i -eq 5 ] || sleep 5
          done

  check-matrix:
    name: check-matrix
    needs: check-dependencies
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
      actions: write

    strategy:
      fail-fast: false
      matrix:
        system: [x86_64-linux]
        check-type: [my-crate-clippy, my-crate-nextest]

    steps:
      - uses: actions/checkout@v5
      - uses: nixbuild/nix-quick-install-action@v32
        with:
          nix_conf: |
            keep-env-derivations = true
            keep-outputs = true

      - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client login nex https://nix.example.com ${{ secrets.ATTIC_TOKEN }} || true
      - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client cache create <cache name> || true
      - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client cache configure <cache name> -- --priority 30 || true
      - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client use <cache name> || true

      - name: check
        run: |
          nix run -I nixpkgs=channel:nixos-unstable nixpkgs#nix-fast-build -- --flake ".#checks.$(nix eval --raw --impure --expr builtins.currentSystem).${{ matrix.check-type }}" --no-nom --skip-cached

      - name: Push to attic
        if: always()
        run: |
          valid_paths=""
          for path in /nix/store/*/; do
            if nix path-info "$path" >/dev/null 2>&1; then
              valid_paths="$valid_paths $path"
            fi
          done

          if [ -n "$valid_paths" ]; then
            for i in {1..10}; do
              nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client push <cache name> $valid_paths && break || [ $i -eq 5 ] || sleep 5
            done
          fi
```

## Forgejo Actions Install
See [Available runner images](../forgejo-github-to-forgejo-actions) for the `runs-on` image
```yaml
name: nix

on:
  pull_request:
    branches: [main]
  push:
  schedule:
    - cron: 0 0 * * 1

env:
  CARGO_TERM_COLOR: always
  NIX_CONFIG: "experimental-features = nix-command flakes"

jobs:
  check-dependencies:
    name: check-dependencies
    runs-on: nix
    permissions:
      contents: read
      id-token: write
      actions: write

    steps:
      # Add secrets.ATTIC_TOKEN here https://forgejo.example.com/user/settings/actions/secrets
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

      - uses: actions/checkout@v5

      - run: nix build -I nixpkgs=channel:nixos-unstable nixpkgs#nix-fast-build

      - name: check
        run: |
          nix run -I nixpkgs=channel:nixos-unstable nixpkgs#nix-fast-build -- --no-nom --skip-cached

      - name: Push to attic
        if: always()
        run: |
          valid_paths=""
          for path in /nix/store/*/; do
            if nix path-info "$path" >/dev/null 2>&1; then
              valid_paths="$valid_paths $path"
            fi
          done

          if [ -n "$valid_paths" ]; then
            for i in {1..10}; do
              nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client push <cache name> $valid_paths && break || [ $i -eq 5 ] || sleep 5
            done
          fi
```
