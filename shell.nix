{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    ruby_3_4
    bundler
    nodejs
    nodePackages.tailwindcss
    yarn
    postgresql
    pkg-config
    git
    zlib
    openssl
    libyaml
    bundix
  ];

  shellHook = ''
    export GEM_HOME="$(pwd)/vendor/bundle/ruby/3.4.0"
    export PATH="$GEM_HOME/bin:$HOME/.local/share/gem/ruby/3.4.0/bin:$PATH"
    export RAILS_ENV=development
    export TAILWINDCSS_INSTALL_DIR=${pkgs.tailwindcss}/bin

    # Install gems if needed
    if [ ! -d "vendor/bundle" ]; then
      bundle config set --local path "vendor/bundle"
      bundle install
    fi
  '';
}
