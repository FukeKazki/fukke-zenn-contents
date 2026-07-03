{
  description = "Dev shell for Zenn (Nix-first)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    }:
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = import nixpkgs { inherit system; };

        zennCliLockFile = builtins.path {
          path = ./nix/zenn-cli-package-lock.json;
          name = "zenn-cli-package-lock.json";
        };

        # nixpkgs に無い npm パッケージは flake 側で取得する
        # textlint-disable / textlint-enable のコメント指示を解釈するために必要
        textlintFilterRuleComments = pkgs.stdenvNoCC.mkDerivation {
          pname = "textlint-filter-rule-comments";
          version = "1.2.2";

          src = pkgs.fetchurl {
            url = "https://registry.npmjs.org/textlint-filter-rule-comments/-/textlint-filter-rule-comments-1.2.2.tgz";
            hash = "sha256-gQBg91bgXFPBlZjhtM5/91yFZL851atmlLIoUQkd5B0=";
          };

          unpackPhase = ''
            runHook preUnpack
            tar -xzf "$src"
            runHook postUnpack
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p "$out/lib/node_modules/textlint-filter-rule-comments"
            cp -R package/* "$out/lib/node_modules/textlint-filter-rule-comments/"
            runHook postInstall
          '';
        };

        # nixpkgs は 0.2.10 のため、npm から最新版を取得する
        zennCli = pkgs.buildNpmPackage rec {
          pname = "zenn-cli";
          version = "0.5.2";

          src = pkgs.fetchurl {
            url = "https://registry.npmjs.org/zenn-cli/-/zenn-cli-0.5.2.tgz";
            hash = "sha256-NiYeE6iMq9+bklvY4hSwR+D7HROC2mZQcnNK7I8j9RY=";
          };

          sourceRoot = "package";

          nativeBuildInputs = [ pkgs.jq ];

          postPatch = ''
            cp ${zennCliLockFile} package-lock.json
            jq 'del(.devDependencies)' package.json > package.json.tmp
            mv package.json.tmp package.json
          '';

          npmDepsHash = "sha256-yNGWP50X42tzG4EXNDaIb7geh8gTOJdBKc3nkjxOUtU=";
          npmFlags = [ "--omit=dev" ];
          dontNpmBuild = true;

          meta.mainProgram = "zenn";
        };

        # textlint が preset ルールを見つけられるようにする
        nodePath = pkgs.lib.makeSearchPath "lib/node_modules" [
          pkgs.textlint-rule-preset-ja-spacing
          pkgs.textlint-rule-preset-ja-technical-writing
          textlintFilterRuleComments
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nodePackages.textlint
            textlint-rule-preset-ja-spacing
            textlint-rule-preset-ja-technical-writing
            zennCli
            textlintFilterRuleComments
          ];

          shellHook = ''
            export NODE_PATH="${nodePath}"
            echo "DevShell:"
            echo "  - textlint $(textlint --version)"
            echo "  - zenn-cli $(zenn --version)"
            echo ""
            echo "Run:"
            echo "  textlint \"./{articles,books}/*.md\""
            echo "  zenn preview"
          '';
        };
      });
}
