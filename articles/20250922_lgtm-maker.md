---
title: "社内用のLGTM Makerを作った"
emoji: "🤖"
type: "tech"
topics: ["vercel"]
published: false
publication_name: "yoshinani_dev"
---

## はじめに

楽しくコードレビューをするため、社内用のLGTM Makerを作成しました。
既存のサービスでもLGTM画像の生成はできますが、外部に公開されるため、今回は社員の写真や身内ネタを楽しむためのプライベートなツールとして開発しました。
LGTMの他にも「Do Not Merge」やカスタムテキストの挿入、文字色の変更などの機能も実装しています。

| | |
| -- | -- |
| ![](https://storage.googleapis.com/zenn-user-upload/04c4571792b5-20250928.png) | ![](https://storage.googleapis.com/zenn-user-upload/644b7e7f5b23-20250928.png) |



## アーキテクチャ

![](https://storage.googleapis.com/zenn-user-upload/3ed3db2033c0-20250924.png)

### ストレージ

生成した画像の保存には、Vercel Blobを利用しました。
Vercel BlobはVercelが提供するファイルストレージサービスで、画像や動画などのバイナリファイルを簡単にアップロード・配信できます。

```tsx:取得
import { list } from "@vercel/blob";

const { blobs } = await list();
```

```tsx:アップロード
import { put } from "@vercel/blob";
const blob = await put(`lgtm.png`, await image.blob(), {
  access: "public",
});
```

### Basic認証

社員のみがアクセスできるようにするため、Basic認証を実装しました。
Next.jsのMiddleware上でBasic認証を行っています。

```tsx:Basic 認証のサンプルコード
export function middleware(req: NextRequest) {
  const basicAuth = req.headers.get("Authorization");
  
  if (!basicAuth) {
    return NextResponse.json(
      { error: "Please enter credentials" },
      {
        headers: { "WWW-Authenticate": 'Basic realm="Secure Area"' },
        status: 401,
      }
    );
  }

  const authValue = basicAuth.split(" ")[1];
  if (!authValue) {
    return NextResponse.json(
      { error: "Please enter credentials" },
      {
        headers: { "WWW-Authenticate": 'Basic realm="Secure Area"' },
        status: 401,
      }
    );
  }

  const [user, password] = atob(authValue).split(":");
  if (user !== process.env.BASIC_AUTH_USER || password !== process.env.BASIC_AUTH_PASSWORD) {
    return NextResponse.json(
      { error: "Invalid credentials" },
      {
        headers: { "WWW-Authenticate": 'Basic realm="Secure Area"' },
        status: 401,
      }
    );
  }

  return NextResponse.next();
}
```

### 画像の圧縮

大きい画像をそのままVercel Blobにアップロードすると課金が発生するため、フロントエンドで圧縮してからアップロードするようにしました。
`browser-image-compression`というライブラリを利用しました。
このライブラリは指定のサイズになるまで繰り返し圧縮を行い、ファイルサイズを効率的に削減できます。

```tsx:画像圧縮のサンプルコード
import imageCompression from "browser-image-compression";

export const compressImage = async (file: File) => {
  const options = {
    maxSizeMB: 0.05,
    initialQuality: 0.3,
    maxWidthOrHeight: 400,
    maxIteration: 20,
    useWebWorker: true,
  };
  return await imageCompression(file, options);
};
```

### LGTM 画像の生成

@vercel/ogを使って画像と「LGTM」の合成をしました。
@vercel/ogはVercelが開発したOG（Open Graph）画像生成ライブラリで、React JSXを使って動的に画像を生成できます。HTMLとCSSライクな記法で画像レイアウトを定義でき、フォントやスタイルのカスタマイズも可能です。Edge Runtimeで動作するため高速で、SNSシェア用画像やサムネイル生成に最適です。

```tsx:@vercel/ogのサンプルコード
const image = new ImageResponse(
  (
    <div
      style={{
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        width: "100%",
        height: "100%",
        backgroundImage: `url(data:${imageMimeType};base64,${imageBase64})`,
        backgroundSize: "cover",
        backgroundPosition: "center",
      }}
    >
      <span
        style={{
          fontSize,
          color: textColor,
          fontFamily: font,
          fontWeight: "bold",
        }}
      >
        LGTM
      </span>
    </div>
  ),
  {
    width,
    height,
    fonts: [
      {
        name: font,
        data: await loadGoogleFont(font, "LGTM"),
        style: "normal",
      },
    ],
  }
);
```

## まとめ

社内のコードレビュー文化を育てるための取り組みとして、LGTM Makerを開発しました。

今回のプロジェクトで使用した主な技術：

- **Vercel Blob**: 画像ファイルの保存・配信
- **@vercel/og**: 画像とテキストの合成
- **browser-image-compression**: 画像の圧縮処理
- **Next.js Middleware**: Basic認証の実装

社員の写真を使ったオリジナルなLGTMや「Do Not Merge」画像を生成することで、コードレビューがより楽しく、親しみやすいものになりました。
チーム全体のレビュー文化の向上につながればいいなと思っています。

![](https://storage.googleapis.com/zenn-user-upload/c71709ee8cac-20250928.png)