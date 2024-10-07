---
title: "手軽なブックマーク管理ツールを作る"
emoji: "🔖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["tridactyl", "peco", "Supabase"]
published: true
---

![Image from Gyazo](https://i.gyazo.com/74278032d1bdde1235e91508474c080b.gif)
_記事をブックマークしてターミナルから開く様子_

# はじめに

以下の図の構成でサイトのブックマークを管理できるツールを作成しました。
![構成図](https://storage.googleapis.com/zenn-user-upload/66b4a4f2f036-20231112.jpg)
_構成図_

# 構成の説明

構成図の説明をします。

ブックマークのデータ保存には[Supabase](https://supabase.com/)を使います。

Supabaseにarticlesテーブルを作成し、記事を登録します。
記事のデータ構造は、以下のようにしました。
![記事のデータ構造](https://storage.googleapis.com/zenn-user-upload/fc708c38a250-20231112.png)
_記事のデータ構造_

# ブックマークの登録

筆者はブラウザにFirefoxを使っているため、Firefoxから簡単にブックマークを登録できるようにしました。
[Tridactyl](https://github.com/tridactyl/tridactyl)はVim操作や特定のキー入力でプログラムを実行できるようになるFirefoxプラグインです。

今回は`,r`キーの入力で閲覧しているサイトをブックマークに登録します。

tridactylの設定で`,r`入力時に`bookmark.js`を実行するようにします。

```text:tridactylrc
" ブックマークに登録する
command bookmark js -r js/bookmark.js
bind ,r composite bookmark | fillcmdline_nofocus
```

次に、`bookmark.js`を作成します。

サイトのタイトルは`document.title`、URLは`location.href`で取得します。
Supabaseへのポストは`fetch`関数で行います。
`return [${title}](${url})`はプログラム実行後、ブラウザ下部に表示される文字列です。

```js:js/bookmark.js
(async function () {
  const SUPABASE_URL = "SUPABASE_URL";

  const title = document.title;
  const url = location.href;

  await fetch(`${SUPABASE_URL}/rest/v1/articles`, {
    method: "post",
    headers: {
      "Content-Type": "application/json",
      apikey: "API_KEY",
    },
    body: JSON.stringify({
      title,
      url,
    }),
  });

  return `[${title}](${url})`;
})();
```

![Image from Gyazo](https://i.gyazo.com/60660da7264da8eea939104e8a64e4ce.gif)
_`,r`で記事がSupabaseに保存される様子_

# ブックマークの取得

`curl`でブックマークを取得し、`peco`で選択UIを作成し、`open`コマンドでブラウザが開くようにします。

取得したブックマーク配列から`jq`コマンドでtitleだけとりだし、`peco`に渡します。
選択したtitleから対応するurlを探して`open`コマンドに渡します。

```bash:.zshrc
function peco-select-bookmark() {
  local bookmarks=$(curl -s 'SUPABASE_URL/rest/v1/articles' -H "apiKey: API_KEY" -H "Content-Type: application/json")
  local bookmark=$(echo $bookmarks | jq -r '.[] | .title' | peco --query "$LBUFFER")
  if [ -n "$bookmark" ]; then
      local selected_bookmark=$(echo $bookmarks | jq -r ".[] | select(.title == \"${bookmark}\") | .url")
      BUFFER="open ${selected_bookmark}"
      zle accept-line
  fi
   zle clear-screen
}
zle -N peco-select-bookmark
bindkey '^U' peco-select-bookmark
```

![Image from Gyazo](https://i.gyazo.com/532928402d4b381900d2f46415f839ce.gif)
_ターミナルでブックマーク一覧から記事を選択する様子_

# おわりに

以上で手軽なブックマークツールが完成しました。
データベースに保存できたことで端末間の同期ができます。また、TUIからの操作なので普段vim生活をしている筆者はとても使いやすく感じています。

技術的には、初めてSupabaseを利用しました。
RDSの無料枠がある点や簡単にCRUDできる点がとても便利でした。

次は、ブックマークするときに記事のメモを登録できるようにしたいです🐱。
