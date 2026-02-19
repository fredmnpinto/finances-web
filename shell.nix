{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.ruby_3_4
    pkgs.bundler
    pkgs.nodejs
    pkgs.yarn
    pkgs.postgresql
    pkgs.pkg-config
    pkgs.git
    pkgs.zlib
    pkgs.openssl
    pkgs.libyaml
  ];

  shellHook = ''
    export GEM_HOME="$(pwd)/vendor/bundle/ruby/3.4.0"
    export PATH="$GEM_HOME/bin:$HOME/.local/share/gem/ruby/3.3.0/bin:$PATH"
    export RAILS_ENV=development
    
    # Install gems if needed
    if [ ! -d "vendor/bundle" ]; then
      bundle config set --local path '"'"'vendor/bundle'"'"'
      bundle install
    fi
  '';
}
