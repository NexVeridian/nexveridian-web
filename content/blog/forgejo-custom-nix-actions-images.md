+++
title = "Creating custom `Nix` Forgejo actions images"
date = 2025-08-25

[taxonomies]
tags = ["forgejo", "nix", "CI", "actions", "docker"]
+++

## Creating custom runner images
`git clone ssh://git@git.nexveridian.com:222/NexVeridian/docker-nixpkgs.git`

### Create a copy of `images/action-attic`
```nix
{
  docker-nixpkgs,
  pkgs,
  attic-client,
  nodejs_24,
  nix-fast-build,
  # add more packages here
}:
(docker-nixpkgs.nix.override {
  nix = pkgs.nixVersions.latest;

  extraContents = [
    attic-client
    nodejs_24
    nix-fast-build
    # and the corresponding packages here
  ];
}).overrideAttrs
  (prev: {
    meta = (prev.meta or { }) // {
      description = "Forgejo action image, with Nix and Attic client";
    };
  })
```

### Edit folder name in `.forgejo/workflows/nix.yaml`
```yaml
- name: Build Nix package
  run: nix-build -A action-attic
```
