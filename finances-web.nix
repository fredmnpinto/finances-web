{ pkgs }:

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
pkgs.stdenv.mkDerivation {
  pname = "finances-web";
  version = "v2026.3.0";

  src = ./.;

  nativeBuildInputs = [
    pkgs.pkg-config
  ];

  buildInputs = [
    gems
    pkgs.nodejs
    pkgs.nodePackages.tailwindcss
    pkgs.yarn
    pkgs.postgresql
    pkgs.git
    pkgs.zlib
    pkgs.openssl
    pkgs.libyaml
    pkgs.vips
  ];

  TAILWINDCSS_INSTALL_DIR="${pkgs.tailwindcss}/bin";

  buildPhase = ''
    runHook preBuild

    cp -r $src/. .
    chmod -R +w .

     export HOME=$TMPDIR
     export BUNDLE_GEMFILE=$src/Gemfile

    ${gems}/bin/bundle exec rails assets:precompile
    ${gems}/bin/bundle exec rails tailwindcss:build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/

    # Copy gems into the package (only what exists)
    mkdir -p $out/gems
    cp -r ${gems}/lib $out/gems/
    if [ -d "${gems}/bin" ]; then cp -r ${gems}/bin $out/gems/; fi

    # Create wrapper script for nix run
    mkdir -p $out/bin
    cat > $out/bin/finances-web << 'WRAPPER'
#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -z "$HOME" ]; then HOME=/tmp; fi
export HOME
export BUNDLE_GEMFILE="$SCRIPT_DIR/../Gemfile"
export BUNDLE_PATH="$SCRIPT_DIR/../gems"
exec "$SCRIPT_DIR/../gems/bin/bundle" exec rails server -p 3000 -b 0.0.0.0 "$@"
WRAPPER
    chmod +x $out/bin/finances-web

    runHook postInstall
  '';
}
