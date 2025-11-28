---
title: "AIコーディング時代のLinter/Formatter運用と独自スタイルガイドの作成"
emoji: "📝"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["javascript", "typescript"]
published: false
---

> この記事は「YOSHINANI&ねこねこパラダイス Advent Calendar 2025」の1日目です。https://adventar.org/calendars/12110

株式会社YOSHINANIのふっけです。
今回は、社内のコード品質を担保するために作成した style-guide パッケージの運用と、その背景にある技術的な意思決定について共有します。

https://github.com/yoshinani-dev/style-guide
https://www.npmjs.com/package/@yoshinani/style-guide

## 背景：vercel/style-guide のアーカイブ

これまで弊社では、Next.jsを中心とした開発において Vercel社が公開していた vercel/style-guide をベース設定として利用していました。多くのプロジェクトで標準的に使われていた優れた設定集でしたが、同リポジトリがアーカイブ（メンテナンス終了）となりました。

https://github.com/vercel/style-guide

これを機に、外部依存を減らし、弊社の技術選定やコーディングガイドラインに完全に準拠した独自の設定パッケージ @yoshinani/style-guide を開発・公開することにしました。

## 課題：AIコーディング支援とコード品質の維持

独自パッケージ化を進めた背景には、開発フローの変化もあります。
GitHub Copilot等のAIコーディング支援ツールが普及し、コード生成のコストは大幅に下がりました。一方で、AIが生成するコードのスタイルや品質をどのように統制するかという課題が生じています。

プロンプトで「キャメルケースを使用する」「インポート順序を整理する」といった指示を毎回与えるのは効率的ではありません。

「AIにはコード生成に専念させ、スタイルや構文上の制約はLinter/Formatterで機械的に矯正する」

この役割分担を明確にするため、プロジェクトごとの設定差異を無くし、強固なルールセットを共通化する必要がありました。

## 解決策：YOSHINANI スタイルガイドの設計

今回作成した style-guide は、以下のツール設定を含んでいます。

- **Prettier / Biome** フォーマッター（選択式）
- **ESLint** リンター
- **TypeScript** tsconfig のベース設定
- **commitlint** コミットメッセージの規約統一
- **CSpell** スペルチェック

### 収録しているルールの具体例

本パッケージには、チームの生産性とコード品質を最大化するための「こだわりの設定」がいくつか含まれています。その一部を紹介します。

#### 1. ESLint Rules

基本的には next/core-web-vitals や typescript-eslint の推奨設定をベースにしつつ、可読性と保守性を高めるためのルールを追加しています。

```js:base.mjs
export default tseslint.config(
  {
    rules: {
      // any禁止
      "@typescript-eslint/no-explicit-any": "error",
      // 構文の禁止
      "no-restricted-syntax": [
        "error",
        {
          // enum禁止
          selector: "TSEnumDeclaration",
          message:
            "TSのenumには様々な問題があります。enum の代わりに as constを使用してください。",
        },
      ],
      // インポートを制限
      "no-restricted-imports": [
        "warn",
        {
          paths: [
            {
              name: "axios",
              message: "Web標準のfetchを使用してください。",
            },
            ...
          ],
          patterns: [
            {
              group: ["lodash/*"],
              message: "remedaを使用してください。",
            },
            ...
          ],
        },
      ],
    },
  },
)
```

#### 2. Commitlint Rules

コミットメッセージのフォーマットには Conventional Commits を採用しています。
feat, fix などのプレフィックスを強制することで、将来的なリリースノートの自動生成や、変更内容の粒度を揃える狙いがあります。

```js:commitlint.config.mjs
export default {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "type-enum": [
      2,
      "always",
      [
        "build", // ビルドシステムや依存関係のみの変更
        "docs", // ドキュメントのみの変更
        "feat", // 新機能
        "fix", // バグ修正
        "refactor", // バグ修正や新機能追加以外のコード変更
        "test", // テストの追加や既存テストの修正
        "release", // 自動リリース専用
      ],
    ],
  },
}
```

#### 3. CSpell (Spell Checker)

変数名やコメントのタイポは、検索性の低下や誤解を招く原因になります。
cspell を導入し、一般的な英単語に加えて、プロジェクト固有の技術用語を辞書登録しています。

これにより、ケアレスミスをCI等の早い段階で検知し、コードレビューで「スペル間違ってますよ」と指摘する時間をゼロにしています。

```txt:word.txt
biomejs
commitlint
dify
esbuild
firestore
injecfn
liff
mjsx
...
```

### 利用方法

#### 1. インストール

すべての設定は1つのパッケージに含まれています。

```bash
npm i --save-dev @yoshinani/style-guide
```

#### 2. ESLint設定

フレームワークや用途に合わせて、最適な設定を extends して利用します。Next.jsプロジェクトであれば以下のように記述します。

```js:eslint.config.mjs
import next from "@yoshinani/style-guide/eslint/next"

const eslintConfig = [...next]

export default eslintConfig
```


#### 3. Prettier と Biome の使い分け

本スタイルガイドの特徴として、標準的な Prettier に加え、高速なフォーマッター・リンターである Biome にも対応しています。プロジェクトの要件に応じて選択可能です。

Prettierを利用する場合:
package.json に以下を追加するだけで適用されます。

```json:package.json
{
  "prettier": "@yoshinani/style-guide/prettier"
}
```

Biomeを利用する場合:
Biomeを利用する場合の設定も同梱しています。biome.jsonc を作成し、以下のように継承します。

```json:biome.jsonc
{
  "$schema": "./node_modules/@biomejs/biome/configuration_schema.json",
  "extends": ["@yoshinani/style-guide/biome"],
  "files": {
    "includes": ["**", "!**/.next", "!**/.turbo"]
  }
}
```

## 技術選定と合意形成について

本パッケージのルールの基盤となっている、弊社の技術選定プロセスや合意形成の仕組みについては、以下の記事で詳しく解説しています。なぜこのルールになったのか、その「Why」に興味がある方はぜひご覧ください。

https://zenn.dev/yoshinani_dev/articles/2de972e13d716d

## まとめと今後の展望

AIによるコード生成が前提となる時代において、静的解析ツールによる品質担保の重要性は以前にも増して高まっています。

今回紹介したのは「ルールの定義」部分ですが、実際のプロジェクト運用では、このスタイルガイドを確実に機能させるために以下のような仕組みも組み合わせています。

- **CIの構築**: GitHub Actions等でプルリクエスト時に自動チェックを行う
- **Git Hooks**: Huskyやlint-stagedを使い、コミット前に不適合なコードを弾く
- **Coding Agentへの指示**: `.cursorrules`や Copilot Custom Instructions にスタイルガイドの情報を渡し、AIにあらかじめルールを遵守させる

これらを組み合わせることで、人間もAIも迷わずに、かつ高品質なコードを書き続けられる環境が整います。
これらの具体的な設定やCoding Agentとの連携ノウハウについては、また別の記事で詳しく解説したいと思います。

今回作成した `@yoshinani/style-guide`が、同様の技術スタック（Next.js / TypeScript / Tailwind CSS）を採用している方々の参考になれば幸いです。