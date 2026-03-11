{
  description = "Finances Web - Rails application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      packages.${system}.default = pkgs.callPackage ./finances-web.nix { };

      devShells.${system}.default = import ./shell.nix { inherit pkgs; };
      runScript = "zsh";
    };
}
