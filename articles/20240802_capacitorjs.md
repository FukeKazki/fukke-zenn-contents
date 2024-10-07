---
title: "CapacitorJSで始めるアプリ開発"
emoji: "🌊"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["react", "capacitor"]
published: true
---

## はじめに
Webアプリをモバイルアプリ化するツールとして、[CapacitorJS](https://capacitorjs.jp/)を紹介します。

CapacitorJSはクロスプラットフォーム開発のためのライブラリです。
既存のWebアプリをiOSやAndroidアプリとして展開することや、Web技術でアプリ開発が可能です。

今回は、CapacitorJSを使ってReactで作ったWebアプリをiOSアプリとAndroidアプリにする方法と実際に運用する上でのTipsを紹介します。

## Reactアプリの作成

まずは、Reactアプリを作成します。
[Viteのドキュメント](https://vitejs.dev/guide/)に沿ってReact-tsプロジェクトを作成します。

```bash
pnpm create vite . --template react-ts
```

Reactアプリが作成できました。
次に、CapacitorJSを導入し、iOSアプリとAndroidアプリを作成します。

### CapacitorJSの導入

```bash
pnpm add @capacitor/core @capacitor/cli
pnpm exec cap init
```

`pnpm exec cap init`を実行すると、CapacitorJSの初期設定が行われます。
アプリ名などが聞かれるのでいい感じに回答していきます。

```bash:initの実行結果
~/Develop/github.com/fuke/capacitor-sample ❯ pnpm exec cap init  
[?] What is the name of your app?
    This should be a human-friendly app name, like what you'd see in the App Store.
✔ Name … capacitor-sample
[?] What should be the Package ID for your app?
    Package IDs (aka Bundle ID in iOS and Application ID in Android) are unique identifiers for apps. They must be in
    reverse domain name notation, generally representing a domain name that you or your company owns.
✔ Package ID … com.example.fuke
✔ Creating capacitor.config.ts in /Users/fuke/Develop/github.com/fuke/capacitor-sample in 6.00ms
[success] capacitor.config.ts created!

Next steps:
https://capacitorjs.com/docs/getting-started#where-to-go-next
```

CapacitorJSの初期設定が完了すると`capacitor.config.ts`ファイルが作成されます。
次に、iOSアプリを作成しシミュレーターで動かします。

### iOSアプリの作成

iOS関連のパッケージを導入します。

```bash
pnpm add  @capacitor/ios
pnpm exec cap add ios
```

アプリに組み込むためにReactアプリをビルドします。

```bash
pnpm run build
```

最後に、ビルドしたReactアプリをiOSアプリに組み込みます。

```bash
# pod installなどが実行される
pnpm exec cap sync
pnpm exec cap run ios
```

`pnpm exec cap run ios`を実行すると、アプリをインストールする端末の選択画面が表示されるのでデバイスを選択して起動します。

```bash:run iosの実行結果
~/Develop/github.com/fuke/capacitor-sample ❯ pnpm exec cap run ios
✔ Copying web assets from dist to ios/App/App/public in 7.16ms
✔ Creating capacitor.config.json in ios/App/App in 545.75μs
[info] Inlining sourcemaps
✔ copy ios in 16.12ms
✔ Updating iOS plugins in 1.12ms
✔ Updating iOS native dependencies with pod install in 2.09s
✔ update ios in 2.14s
? Please choose a target device: › - Use arrow-keys. Return to submit.
    iPad (10th generation) (simulator) (866CDB04-D834-4A01-BB4E-579A607DFC59)
    iPad Air (5th generation) (simulator) (CC1DAEE8-6FED-417E-81E0-E4CC070CA967)
    iPad Pro (11-inch) (4th generation) (simulator) (657F086C-A79C-4BC6-983D-0F801107B893)
    iPad Pro (12.9-inch) (6th generation) (simulator) (D1CA5AB4-EAB5-4A1D-AA50-549B87B7645C)
    iPad mini (6th generation) (simulator) (572D2FF1-EFE3-4DDC-8000-011F240C69B3)
    iPhone 15 (simulator) (26056240-0168-464B-804D-BDD0468EFFCB)
    iPhone 15 Plus (simulator) (A4513913-2ADF-4A85-81D4-3ED50BC6DD7F)
    iPhone 15 Pro (simulator) (C9AD36F6-B342-4587-B501-5A570B153022)
  ↓ iPhone 15 Pro Max (simulator) (61C916DD-6F66-4128-BD3B-92AD612B94E6)
```

無事インストールが完了すると、iOSアプリが起動します。

![](https://storage.googleapis.com/zenn-user-upload/a54344d6aacd-20240417.png =300x)
*iOSアプリの画面*

### Androidアプリの作成

Androidも同様の手順でパッケージを導入していきます。

```bash
pnpm add @capacitor/android
pnpm exec cap add android
```

ReactアプリをAndroidアプリに組み込みます。

```bash
pnpm exec cap sync
pnpm exec cap run android
```

アプリをインストールする端末の選択画面が表示されるのでデバイスを選択して起動します。

![](https://storage.googleapis.com/zenn-user-upload/ce74d262c0ba-20240417.png =300x)
*Androidアプリの画面*

ここまでの流れは以下の記事でも詳しく解説されています。
https://zenn.dev/chot/articles/b7f9feb2c39bc1

## Tips
### ローカル開発方法
Capacitorを使った開発ではWeb技術による開発のためブラウザ上で確認しながら進めることができます。
アプリでの動作確認をしたいときは`capacitor.config.ts`を書き変えて実現します。
これでシミュレーターで開発サーバーを見てホットリロードの効く環境での開発ができます。

```bash
vite # localhost:5173で起動
```

```ts:capacitor.config.ts
const config = {
  server: {
    url: "http://localhost:5173",
    hostname: "localhost"
  },
}
```

Androidのシミュレーターではlocalhostの解決ができないのでIPを直で指定してあげます。

```bash
vite --host 0.0.0.0 # 192.168.0.0などで起動
```

```ts:capacitor.config.ts
const config = {
  server: {
    url: "http://192.168.0.0:5173",
  },
}
```

### StatusBarの色を変更
デフォルトではStatusBarの色はシステムのテーマによって自動で変更されます。
アプリのテーマカラーと合わたりでカスタマイズしたい場合には`@capacitor/status-bar`を使います。

```tsx
import { StatusBar, Style } from '@capacitor/status-bar';

if (!Capacitor.isNativePlatform()) {
  return;
}
StatusBar.setStyle({ style: Style.Dark })
StatusBar.setBackgroundColor({ color: "#ffffff" });
```

![](https://storage.googleapis.com/zenn-user-upload/95f635053a4f-20240802.png =300x)
*AndroidアプリでStatusBarの色を変更*

### Firebase Authで認証
`@capacitor-firebase/authentication`を使ってAppleログインやGoogleログインの実装ができます。

```tsx
import { FirebaseAuthentication } from "@capacitor-firebase/authentication";

// Googleでサインイン
await FirebaseAuthentication.signInWithGoogle({
  scopes: ["profile", "email"],
})

// FirebaseのIDトークンを取得
const { token } = await FirebaseAuthentication.getIdToken();
```

```ts:capacitor.config.ts
const config = {
    FirebaseAuthentication: {
      skipNativeAuth: false,
      providers: ["google.com"],
    },
}
```

メインのコードは以上ですが、フィンガープリントの設定なども必要です。詳しくは以下のドキュメントを参考にしてください。
https://github.com/capawesome-team/capacitor-firebase/blob/main/packages/authentication/docs/setup-google.md#set-up-authentication-using-google-sign-in

### スクショ対策
`@capacitor-community/privacy-screen`を使うとスクリーンショットを検知して禁止する処理ができます。

```tsx
import { PrivacyScreen } from "@capacitor-community/privacy-screen";

PrivacyScreen.enable();
```

![](https://storage.googleapis.com/zenn-user-upload/635c473abd40-20240802.png =300x)
*Androidアプリでスクショ*

### シェア
`@capacitor/share`を使うとWebShare APIを使ったシェアができます。

```tsx
import { Share } from '@capacitor/share';

Share.share({
  text: "日記をシェアします",
  files: ["https://pbs.twimg.com/profile_images/1268770710035390464/OqxEBvzz_400x400.jpg"]
})
```

![Image from Gyazo](https://i.gyazo.com/c7a4cf51d8051a1e42b9d1fbead4a324.gif =300x)
*iOSアプリでシェア*

## おわりに
CapacitorJSの導入とTipsの紹介をしました。
Web技術でアプリ開発をしたい方や、既存のWebサービスをアプリ化するのにおすすめのライブラリです。
ぜひ試してみてください 💫
