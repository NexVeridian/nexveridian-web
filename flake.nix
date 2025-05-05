{
  description = "Flake for building container for Zola static site";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Build the static website with Zola
        my-zola = pkgs.stdenv.mkDerivation {
          pname = "zola-static-website";
          version = "0.1.0";
          src = ./.;
          nativeBuildInputs = [ pkgs.zola ];
          buildPhase = "zola build";
          installPhase = "cp -r public $out";
        };

        # Create a Docker image with static-web-server to serve the site
        my-docker = pkgs.dockerTools.buildImage {
          name = "my-zola";
          tag = "latest";
          created = "now";

          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [
              pkgs.static-web-server
              (pkgs.runCommand "docker-public" { } ''
                mkdir -p $out/public
                cp -r ${my-zola}/* $out/public
              '')
            ];
          };

          config = {
            Cmd = [
              "${pkgs.static-web-server}/bin/static-web-server"
              "--port"
              "80"
            ];
            Expose = [ 80 ];
          };
        };
      in
      {
        packages = {
          default = my-docker;
          inherit my-zola my-docker;
        };

        # Development shell with Zola for local work
        devShell = pkgs.mkShell {
          packages = with pkgs; [
            zola
          ];
        };
      }
    );
}
