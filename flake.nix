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
            zenn-cli
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
