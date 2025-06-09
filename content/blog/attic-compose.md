+++
title = "Deploying `Attic` Nix Binary Cache With Docker Compose, for local use and CI"
date = 2025-05-06
# description = "Deploying Attic Nix Binary Cache With Docker Compose."

[taxonomies]
tags = ["nix", "docker", "CI", "cache", "github-actions"]
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
      db:
    volumes:
      - ./server.toml:/attic/server.toml
      - attic-data:/attic/storage
    env_file:
      - prod.env
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "wget --no-verbose --tries=1 --spider http://attic:8080 || exit 1",
        ]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s

  db:
    container_name: db
    image: postgres:17.2-alpine
    restart: unless-stopped
    ports:
      - 5432:5432
    networks:
      db:
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
  db:
```

### Example `server.toml`
```toml
listen = "[::]:8080"

[database]
url = "postgres://attic:attic@db:5432/attic_prod"

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
    - "traefik.http.services.attic.loadbalancer.server.port=8080"
    - "traefik.http.routers.attic-http.middlewares=redirect-to-https"
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
