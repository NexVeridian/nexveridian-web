run:
    zola serve

update:
    nix flake update

docker:
    nix build .#packages.x86_64-linux.my-docker
    docker load < ./result
    docker rm -f my-zola
    docker run -d --rm -p 80:80 --name my-zola my-zola:latest
    rm -rf result
    docker image prune -f
