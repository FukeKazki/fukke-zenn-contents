# Zenn CLI

- [📘 How to use](https://zenn.dev/zenn/articles/zenn-cli-guide)

# slugの命名規則

`yyyymmdd_title`にする。

# Nix devShell（推奨）
  
`nix develop` で Nix 管理の `textlint` / `zenn-cli` を使えます。

```bash
nix develop
textlint "./{articles,books}/*.md"
zenn preview
```

# 画像アップロード先

[https://zenn.dev/dashboard/uploader](https://zenn.dev/dashboard/uploader)
