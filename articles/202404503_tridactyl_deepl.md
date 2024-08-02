---
title: "tridactyl Tips deepl拡張を作る"
emoji: "🐙"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["tridactyl"]
published: false
---

# つくるもの
Firefoxの拡張機能であるtridactyl上で動作するプラグインを作成します。
deeplのAPIを利用して、選択したテキストを翻訳します。

実際の動作はこちらです。

翻訳履歴が積み上がっていくのが推しポイントです。

# 動作環境
- Firefox Developer Edition 126
- [tridactyl](https://github.com/tridactyl/tridactyl)

# deepl API Keyの取得

# APIにリクエストを送る

```javascript:deepl.js
// 選択したテキストを取得
const text = document.getSelection()?.toString();
if (!text) return;

const API_KEY = ""
const ENDPOINT = "https://api-free.deepl.com/v2/translate"

const params = new URLSearchParams({
    text,
    target_lang: "JA",
});

const { translations } = await fetch(new URL(ENDPOINT), { method: "post",
    headers: {
      Authorization: `DeepL-Auth-Key ${API_KEY}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: params,
}).then((res) => res.json());
```

`document.getSelection()?.toString()`はユーザーが選択したテキストを取得できる関数です。
deeplのAPIは`application/x-www-form-urlencoded`形式でリクエストを送る必要があるため、`URLSearchParams`を利用してパラメータを作成します。
`URLSearchParams`の`text`には翻訳前の文章、`target_lang`には翻訳後の言語を指定します。

# tridactylで実行する

```txt:tridactylrc
command deepl js -r js/deepl.js
bind ,d composite deepl
```

`command`で`deepl`というコマンドを作成し、`js -r js/deepl.js`でJSファイルのパスを指定します。
`bind`で`,d`というキーバインドを作成し、`composite deepl`で`deepl`コマンドを実行しています。

これで、翻訳したい文章を選択し`,d`を入力するとdeepl翻訳にAPIリクエストが送信されるようになりました。

あとは翻訳結果をbodyに入れるなどしてブラウザに表示すると完成です。

# まとめ
tridactylを使用すると任意のタイミングでJavaScriptを実行可能です。
`document.getSelection()?.toString()`でユーザーが選択したテキストを取得できるため、それを利用して楽しいことができそうですね。

気になった方はぜひ、Firefox & tridactylを使ってみてください。

# 参考
[tridactyl を使って Firefox を Vim のように制御/拡張する](https://zenn.dev/lambdasawa/articles/tridactyl-introduction)
