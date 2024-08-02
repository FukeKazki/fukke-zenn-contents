---
title: "NextJSでLPを作るときのメモ"
emoji: "🎉"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: []
published: false
---

# OGPの設定

```tsx:layout.tsx
import type { Metadata } from "next";
export const metadata: Metadata = {
  title: "",
  description: "",
  metadataBase: new URL("https://fukke.cafe/"),
  openGraph: {
    type: "website",
    locale: "ja_JP",
    url: "https://fukke.cafe/",
    siteName: "",
    title: "",
    description: "",
  },
  twitter: {
    card: "summary",
    title: "",
    description: "",
    site: "@ahi",
    creator: "@ahi",
  },
};

```

# フォントの設定

`next/font`を使ってGoogle Fontsを読み込む。

````tsx:layout.tsx

```tsx:layout.tsx
import { Noto_Sans_JP } from "next/font/google";

const notoSansJp = Noto_Sans_JP({
  weight: ["400", "500", "700"],
  subsets: ["latin"],
  variable: "--font-noto-sans-jp",
});

<body className={notoSansJp.className}>{children}</body>;
````

# 全角文字と半角文字のカーニング

`（おおもじかっこ）`のように全角文字と半角文字が連続するときに、文字間(カーニング)がおかしくなります。
綺麗にするためには、`font-feature-settings: "palt";`を使う。

tailwindの場合はpaltクラスを作成するのがよさそう。
```
@layer utilities {
  .palt {
    font-feature-settings: "palt";
  }
}
```

# ビルド設定

`output: "export"`を設定すると、`next export`で静的ファイルを出力できるようになる。
静的ビルドでは画像最適化ができないので`images.unoptimized: true`を設定する。

```js:next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "export",
  images: {
    unoptimized: true,
  },
};

module.exports = nextConfig;
```

# 総評
NextJS(AppRouter)でLPは向いていない。
特に画像を最適化できないのが致命的だと感じた。
