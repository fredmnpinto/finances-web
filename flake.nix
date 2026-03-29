{
  description = "Finances Web - Rails application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { 
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      app = pkgs.callPackage ./finances-web.nix { };
    in
    {
      packages.${system} = {
        default = app;
        docker-image = pkgs.dockerTools.buildImage {
          name = "finances-web";
          tag = "latest";

          copyToRoot = pkgs.symlinkJoin {
            name = "finances-web-root";
            paths = [
              (pkgs.buildEnv {
                name = "binlibs";
                paths = [
                  pkgs.bash
                  pkgs.jemalloc
                  pkgs.vips
                  pkgs.postgresql
                  pkgs.cacert
                  pkgs.curl
                  pkgs.coreutils
                ];
                pathsToLink = [ "/bin" "/lib" ];
              })
              app
            ];
          };

          config = {
            Env = [
              "HOME=/app"
              "BUNDLE_GEMFILE=/app/Gemfile"
              "BUNDLE_PATH=/app/gems"
            ];
            Expose = [ 3000 ];
            Cmd = [ "/bin/finances-web" "rails" "server" "-p" "3000" "-b" "0.0.0.0" ];
          };
        };
      };

      devShells.${system}.default = import ./shell.nix { inherit pkgs; };
      runScript = "zsh";
    };
}
