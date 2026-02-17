{
  description = "Finances Web - Rails application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      devShells.x86_64-linux.default = import ./shell.nix { inherit pkgs; };
      runScript = "zsh";
    };
}
