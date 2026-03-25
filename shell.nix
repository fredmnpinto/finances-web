{ pkgs ? import <nixpkgs> { } }:

let
  gems = pkgs.bundlerEnv {
    name = "finances-web-gems";
    ruby = pkgs.ruby_3_4;
    gemdir = ./.;
    gemConfig = pkgs.defaultGemConfig // {
      mini_portile2 = attrs: {
        buildInputs = [ pkgs.libxml2 pkgs.libxslt pkgs.zlib ];
      };
      nokogiri = attrs: {
        buildInputs = [ pkgs.libxml2 pkgs.libxslt pkgs.zlib ];
      };
      pg = attrs: {
        buildInputs = [ pkgs.postgresql ];
      };
      ffi = attrs: {
        buildInputs = [ pkgs.libffi ];
      };
      ruby-vips = attrs: {
        buildInputs = [ pkgs.vips ];
      };
    };
  };
in

pkgs.mkShell {
  buildInputs = with pkgs; [
    gems
    ruby_3_4
    nodejs
    nodePackages.tailwindcss
    yarn
    postgresql
    pkg-config
    git
    zlib
    openssl
    libyaml
    libffi
    vips
  ];

  shellHook = ''
    export RAILS_ENV=development
    export TAILWINDCSS_INSTALL_DIR=${pkgs.tailwindcss}/bin
  '';
}
