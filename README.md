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

# mise タスク（便利コマンド）

`mise` を使う場合は、次のタスクが使えます（内部的には `nix develop` を呼びます）。

```bash
mise run textlint
mise run textlint:fix
mise run preview
```

# 画像アップロード先

[https://zenn.dev/dashboard/uploader](https://zenn.dev/dashboard/uploader)
