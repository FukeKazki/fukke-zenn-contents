---
title: "VSCodeが物足りない人へ AstroNvimの紹介"
emoji: "⌨️"
type: "tech"
topics:
  - "vscode"
  - "neovim"
  - "astronvim"
published: true
published_at: "2023-06-06 15:34"
---

# はじめに

みなさんはエディタに何を使っていますか?
筆者は最近、VSCodeからNeoVimに乗り換えました。
NeoVimは自分好みにカスタマイズしていくエディタです。
この記事ではVSCodeに飽きちゃった人やNeoVimを使ってみたいけど難しそうだなと思っている人に向けて[AstroNvim](https://astronvim.com/) を紹介します。

AstroNvimとはオールインワンのNeovim環境です。

カスタマイズも簡単にできるため、NeoVim初心者にはとてもおすすめです。
筆者もAstroNvimからNeoVimに入門しており、いまも使い続けています。

![筆者の環境](https://storage.googleapis.com/zenn-user-upload/d99a294ecd91-20230603.png)

# AstroNvim のインストール

Macの場合はbrewを使って簡単に導入できます。

```
brew install neovim

git clone --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/nvim
nvim
```

ubuntuの場合は自分でNeovimをビルドするのが良いです。
apt経由で入れると、バージョンが低い場合やLuaJITでビルドできていないことがあります。
以下はubuntuコンテナ環境にAstroNvimを導入する手順です。

```
# Neovimのインストール (自前でビルドする)
## パッケージを導入
sudo apt-get update
sudo apt-get install ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip

# 便利なパッケージを追加
sudo apt-get install ripgrep

## NeoVimをクローン
git clone https://github.com/neovim/neovim
cd neovim/
make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install

# AstroNvimのインストール
cd .config/
git clone --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/nvim

# NeoVimを起動
exec $SHELL -l
nvim
```

以上の手順が完了すればAstroNvimが起動します。

[![Image from Gyazo](https://i.gyazo.com/90aecb7e64df39122eaf8aae640ff2ca.png)](https://gyazo.com/90aecb7e64df39122eaf8aae640ff2ca)

# 操作方法

AstroNvimの操作の大体は`<space>`キーが起点になっています。
`<space>`を入力するとこのように操作の候補が表示されます。
[![Image from Gyazo](https://i.gyazo.com/a0443d596e77f6492fb3d2f23e4e3010.png)](https://gyazo.com/a0443d596e77f6492fb3d2f23e4e3010)
例えば`e`はToggle Explolerでサイドメニューが開いてファイルツリーを操作できます。
これは[NeoTree](https://github.com/nvim-neo-tree/neo-tree.nvim)というプラグインが動作しています。
[![Image from Gyazo](https://i.gyazo.com/c56f7ec0d776530625f0eb14d1a65bf4.png)](https://gyazo.com/c56f7ec0d776530625f0eb14d1a65bf4)

また `<space>ff` でファイル検索 (VSCodeでのcmd + P) や `<space>fw`でワード検索が可能です。
これは[Telescope](https://github.com/nvim-telescope/telescope.nvim) というファインダー機能を提供しているプラグインが動作しています。

![](https://storage.googleapis.com/zenn-user-upload/ce3896d1d556-20230602.gif)

操作に迷ったときは`<space>`キーで一覧を眺めてみてください。

# 自分だけの AstroNvim にカスタマイズ

AstroNvimのカスタマイズについて紹介します。

https://github.com/AstroNvim/user_example の「Create a new Repository」からリポジトリをフォークして自分用の設定ファイルを作成します。

[![Image from Gyazo](https://i.gyazo.com/324b4b788858c641a088759dfbfc73ba.jpg)](https://gyazo.com/324b4b788858c641a088759dfbfc73ba)

フォークしたらリポジトリを `.config/nvim/lua/user`にクローンします。

```
git clone https://github.com/<your_user>/<your_repository> ~/.config/nvim/lua/user
```

主に `plugins`フォルダ以下でカスタマイズをします。
おすすめのカスタマイズ例を紹介します。

## LSP

言語ごとにプログラムの変換候補を表示するためにはLSPの導入が必要です。
AstroNvimには[mason-lsp-config](https://github.com/williamboman/mason-lspconfig.nvim) というプラグインが導入されています。
mason-lsp-configはlanguage server, linter, formatterを統一して管理するためのプラグインです。

`:Mason`でインストールしているLSPが確認できます。

例えば、TypeScriptのLSPをインストールするときは`:MasonInstall typescript-language-server`でインストールできます。

また `plugins/mason.lua`ファイルにあらかじめ書くことで自動インストールも可能です。

```
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = { "lua_ls", "tsserver", "jsonlsp", "yaml-language-server", "tailwindcss" },
    },
  },
```

tailwindcssのLSPが動作している例
[![Image from Gyazo](https://i.gyazo.com/5c9b760146a0d6c04102838426fd73a9.png)](https://gyazo.com/5c9b760146a0d6c04102838426fd73a9)

## Git 操作

筆者はGit操作に [NeoGit](https://github.com/TimUntersberger/neogit) を使っています。
NeoGitはAstroNvimには含まれていないので、自分でプラグインの追加をします。

`plugins/user.lua`に以下を書くとプラグインを導入できます。

```
  {
    "TimUntersberger/neogit",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    dependencies = {
      "sindrets/diffview.nvim",
    },
    config = function()
      require("neogit").setup {
        integrations = {
          diffview = true,
        },
      }
    end,
  },
```

![](https://storage.googleapis.com/zenn-user-upload/f6f8a6068e4d-20230602.gif)

# AstroNvim での日常的な作業

筆者が普段どのように操作しているかgifにして紹介します。

![](https://storage.googleapis.com/zenn-user-upload/f2de429f4f01-20230602.gif)

# トラブルシューティング

NeoVim初心者のころは設定ファイルの書きかたや、プラグインのインストールなどでつまづくことがあります。

AstroNvimは記事が少ないため、[公式ドキュメント](https://astronvim.com/)に頼ることが多いです。

また、copilotのサジェストや[grep.app](https://grep.app/)というプログラムの検索サービスを使って他人の設定ファイルを参考にすることが多いです。

参考に筆者の設定ファイルを載せておきます。

https://github.com/FukeKazki/astronvim3-user

# おわりに

AstroNvimを使ったNeoVimの入門方法について解説しました。
自分だけのエディタを作って最高のNeoVimライフをお過ごしください！。
