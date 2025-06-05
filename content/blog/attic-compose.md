+++
title = "Deploying `Attic` Nix Binary Cache With Docker Compose, for local use and CI"
date = 2025-05-06
# description = "Deploying Attic Nix Binary Cache With Docker Compose."

[taxonomies]
tags = ["nix", "docker", "CI", "cache", "github-actions"]
+++

## Server Install
Install docker and docker compose

`git clone git@github.com:NexVeridian/attic-compose.git`

See `/scr`, create a `prod.env` and `server.toml` files

then run

```bash
just up
just create_token <your username here>
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
    - "traefik.http.services.attic.loadbalancer.server.port=8080"
    - "traefik.http.routers.attic-http.middlewares=redirect-to-https"
    - "traefik.docker.network=<network name>"
```

### Cloudflare
If you are using cloudflare make the subdomain DNS only

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
steps:
  - uses: actions/checkout@v3
  - uses: DeterminateSystems/nix-installer-action@main
  - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client login <pick a name for server> https://nix.example.com ${{ secrets.ATTIC_TOKEN }} || true
  - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client cache create <cache name> || true
  - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client use <cache name> || true

  # `nix-fast-build` is faster then `nix flake check` in my testing, and has support for pushing to attic after each build is finished
  # - run: nix flake check --all-systems
  - run: nix run -I nixpkgs=channel:nixos-unstable nixpkgs#nix-fast-build -- --attic-cache <cache name> --no-nom --skip-cached

  - run: |
      for i in {1..5}; do
        nix run -I nixpkgs=channel:nixos-unstable nixpkgs#attic-client push <cache name> /nix/store/*/ && break || [ $i -eq 5 ] || sleep 5
      done
```
