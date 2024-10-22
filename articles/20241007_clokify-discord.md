---
title: "Clockifyの稼働状況をDiscordへ通知する仕組み"
emoji: "📝"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["hono", "cloudrun"]
published: true
publication_name: "yoshinani_dev"
---

## はじめに
弊社では従業員の稼働状況をClockifyを使って管理しています。
また社内コミュニケーションツールとして使っているDiscordとClockifyを連携させ、稼動状況を通知する仕組みを導入しています。

![](https://storage.googleapis.com/zenn-user-upload/6c5c25e988ce-20241008.png)

今回はClockifyとDiscordを連携する仕組みについて解説します。

## この記事で解説する内容
- ClockiflyとDiscordの連携
- hono * Cloud Runを使ったサーバー構築

## Clockify webhook
ClockifyにはWebhookを送る仕組みがあります。
`Preferences > Advance > Webhooks`から任意のタイミングで発火するWebhookを登録できます。

![](https://storage.googleapis.com/zenn-user-upload/fc3ca5e66953-20241008.png)

例えば `Timer started (anyone)`と`Timer stopped (anyone)`は誰かがTimerを実行、停止したタイミングでWebhookにデータを送ります。

これを使って「誰が」「どのプロジェクト」「どのタスク」を開始、終了したかをDiscordに通知します。

## Discord webhook
DiscordではチャンネルのWebhookを簡単に生成できます。
`チャンネルの編集 > 連携サービス > ウェブフック`から新しいWebhookを生成できます。

![](https://storage.googleapis.com/zenn-user-upload/c16608c304e9-20241008.png)

## ClockifyとDiscordの連携
ClockifyのWebhooksにDiscordのWebhookを登録して動作確認をしましたが、Discordの受けとる形式とClockifyの送る形式が合わなかったため動きませんでした。
そこで今回はサーバーを立てて、Clockifyのデータを整形後、Discordに送るサーバーを作成しました。

### 技術構成
バックエンドフレームワークにhono、インフラにCloudRunを使用しました。
honoでのサンプルを示します。

```ts
import { Hono } from 'hono'
import { serve } from '@hono/node-server'

const app = new Hono()

app.get('/', (c) => {
  return c.text('Hello Hono!')
})

const port = 8080
console.log(`Server is running on port ${port}`)

serve({
  fetch: app.fetch,
  port
})
```

### 連携プログラム

`/clockify`にエンドポイントを作成します。

```ts
app.post('/clockify', async (c) => {
  const res = await c.req.json()

  let content = ''
  if (res.currentlyRunning) {
    // 開始時
    content = `${res.user.name} が ${res.project?.clientName || ''} - ${res.project?.name || ''} ${res?.description || ''} を開始しました. `
  } else {
    // 終了時
    content = `${res.user.name} が ${res.project?.clientName || ''} - ${res.project?.name || ''} ${res?.description || ''} を終了しました. お疲れ様でした.`
  }
  // discordに送信
  await fetch(DISCORD_WEBHOOK, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      content
    })
  })
  return c.status(200)
})
```

currentlyRunningプロパティを見て、タスクの開始または終了を判定します。その後、それに応じたメッセージを作成し、DiscordのWebhook URLへPOSTリクエストを送信して通知します。

### ビルド
tsupを使ってビルドします。NodeJSで実行するためformatはCommonJSを指定します。

```ts:tsup.config.ts
import { defineConfig } from 'tsup'

export default defineConfig({
  entry: ['src/index.ts'],
  format: ['cjs'], // CommonJS
  target: 'node16',
  clean: true // クリーンビルド
})
```

```json:package.json
{
  "name": "clockify-to-discord",
  "main": "dist/index.js",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsup --clean"
  },
}
```

### デプロイ
CloudRunへデプロイするためのイメージを作成します。
CloudRunは8080番ポートを利用する点に注意です。

このDockerfileでは、ビルドフェーズとランナー（実行フェーズ）に分かれています。ビルドフェーズでは、TypeScriptのコードをコンパイルし、/app/distに出力します。その後、ランナーでコンパイル済みのコードを実行するシンプルなコンテナを作成します。

```Dockerfile
FROM node:20-alpine AS base

FROM base AS builder

RUN apk add --no-cache gcompat
WORKDIR /app

COPY . .

RUN corepack enable pnpm && pnpm i --frozen-lockfile && pnpm build

FROM base AS runner
WORKDIR /app

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 hono

COPY --from=builder --chown=hono:nodejs /app/node_modules /app/node_modules
COPY --from=builder --chown=hono:nodejs /app/dist /app/dist
COPY --from=builder --chown=hono:nodejs /app/package.json /app/package.json

USER hono
EXPOSE 8080

CMD ["node", "/app/dist/index.js"]
```

手元でビルドし、Artifact Registryにプッシュします。
Apple Silicon搭載Macでビルドする場合、platformにlinux/amd64を指定しないとCloudRunでの実行ができないため注意です。

```bash
docker buildx build --platform linux/amd64 -t asia-northeast1-docker.pkg.dev/project-name/gcf-artifacts/clokify-to-discord --push .
```

:::message
gcloud-cliを使ってArtifact Registryにイメージをプッシュするには認証が必要になります。
```bash
# 認証
gcloud auth login
# dockerの構成に追加
gcloud auth configure-docker asia-northeast1-docker.pkg.dev
```
:::

Cloud Runのダッシュボードでプッシュしたイメージを選択し、コンテナを作成すれば完成です。

## おわりに
今回は社内ツールの作成をお届けしました。
僕はhonoの利用が初めてでしたが、とても簡単に利用できました。

現在はCloudRunからcloudflare workersに乗り替えて運用しています。パフォーマンスが良くなったかも?

ではまた🥳。