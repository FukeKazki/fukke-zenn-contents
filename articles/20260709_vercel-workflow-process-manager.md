---
title: "Vercel Workflowで実装していたら、それはプロセスマネージャーパターンだった"
emoji: "🔄"
type: idea
topics:
  - vercel
published: true
---

## はじめに

今回は、待機やリトライを含む長い業務フローをVercel Workflowで実装していたら、それがプロセスマネージャーパターンだった、という話を紹介します。

業務効率化の実装を考えていると、「これどう実装するのが正解なんだろう」と悩むことがあります。単純なAPIを呼ぶだけなら難しくありませんが、人の承認待ちや外部サービスの完了待ち、数時間〜数日後の続き実行、途中失敗時のリトライが入ると、APIを順番に呼ぶだけでは破綻しやすいです。

当時はそういう長い処理にVercel Workflowを採用しました。後からDDDの書籍でプロセスマネージャーパターンを知り、自分が実装していたものがそれだと分かりました。

この記事では、Vercel Workflowの書き方を交えつつ、なぜこの用途に合っていたのかをプロセスマネージャーパターンの観点で整理します。

メモとして残していた内容もベースにしています。

[https://zenn.dev/fukke/scraps/f3953ea4a10adb](https://zenn.dev/fukke/scraps/f3953ea4a10adb)

## 例：イベント運営のワークフロー

例えばイベント運営を考えてみます。参加者が申し込みをしても、すぐに参加登録するわけではありません。流れは下記のとおりです。

```
参加申請
  ↓
決済
  ↓
参加枠を確保
  ↓
Discordへ招待
  ↓
開催前日にリマインド送信
```

加えて、次のような制御も必要になります。

- 決済に失敗したら終了
- Discordへの招待に失敗したらリトライ
- 開催前日までは待機

単純にAPIを順番に呼ぶだけでは、待機やリトライ、途中失敗の扱いにすぐ破綻します。

## Vercel Workflow とは

Vercel Workflowは、Vercelが提供するワークフロー実行基盤です。内部ではVercel Functionsがステップを実行し、Vercel Queuesでキュー管理が行われます。

実装自体はWDK（Workflow Development Kit）で書きます。`"use workflow"` と `"use step"` を付けたasync関数を、いつものTypeScriptの書き方で組み立てられます。

主な特徴は下記とおりです。

- 関数の停止と再開ができる
- 失敗時にリトライできる
- `async` / `await` で書ける
- ダッシュボードで実行状況を確認できる（Dashboard > Observability > Workflow）

コストは、Workflow / Stepの実行結果を持つストレージ料金、Stepの実行数、Step実行に伴うFunctions課金がかかります。

## コードで見る実装パターン



### 最小構成

`/test` へのPOSTでワークフローを開始し、10秒後にログを出す最小例です。

```bash
pnpm install workflow
```

```ts:workflows/test-workflow.ts
import { sleep } from "workflow"

export async function testWorkflow() {
  "use workflow"

  // sleep は workflow 内で呼ぶ
  await sleep("10s")
  await hello()
}

async function hello() {
  "use step"

  console.log("hello")
}
```

```ts:api/route.ts
import { start } from "workflow/api"
import { testWorkflow } from "../workflows/test-workflow"

app.post("/test", async (c) => {
  const result = await start(testWorkflow, [])

  return c.json({ message: result.runId })
})
```

ローカルでは次のコマンドで実行状況を確認できます。

```bash
pnpm dlx workflow web
```

ポイントは次のとおりです。

- `"use workflow"`: プロセス全体をオーケストレーションする関数。`sleep` や `hook` もここで使う
- `"use step"`: リトライや永続化の単位になる処理。外部API呼び出し（`fetch` など）はここに書く

`sleep` はstep内では使えません。workflow関数の中で直接呼び出します。

### イベント運営を Workflow で書くと

先ほどのイベント運営の例を、Workflowの形に落とすとだいたい次のようになります。

```ts:workflows/event-registration-workflow.ts
import { sleep } from "workflow"

type RegistrationInput = {
  applicationId: string
  eventDate: string // ISO date
}

export async function eventRegistrationWorkflow(input: RegistrationInput) {
  "use workflow"

  const payment = await chargePayment(input.applicationId)
  if (!payment.ok) {
    return { status: "payment_failed" as const }
  }

  await reserveSeat(input.applicationId)
  await inviteToDiscord(input.applicationId)

  // 開催前日まで待機してからリマインド
  // sleep は workflow 内で呼ぶ。Date を渡すと指定時刻まで待機できる
  const reminderAt = new Date(input.eventDate)
  reminderAt.setDate(reminderAt.getDate() - 1)
  await sleep(reminderAt)

  await sendReminder(input.applicationId)

  return { status: "completed" as const }
}

async function chargePayment(applicationId: string) {
  "use step"
  // 決済APIを呼ぶ
  return { ok: true }
}

async function reserveSeat(applicationId: string) {
  "use step"
  // 参加枠を確保する
}

async function inviteToDiscord(applicationId: string) {
  "use step"
  // Discord招待。失敗時はstepのリトライに任せる
}

async function sendReminder(applicationId: string) {
  "use step"
  // リマインド送信
}
```

各ステップが独立しているので、Discord招待だけ失敗してもそのstepをリトライできます。開催前日までの待機は、workflow内の `sleep` で表現します。

### 外部イベント待ちは hook

決済完了や人の承認など、外部からの合図を待つ場合は `hook` を使います。

- `create()` はworkflow内で呼び、戻り値を `await` して待機する
- `resume()` はworkflow外（API routeやServer Action）から、同じtokenで呼び出す

```ts:workflows/payment-workflow.ts
import { defineHook } from "workflow"
import * as v from "valibot"

export const onPaymentCompletedHook = defineHook({
  schema: v.object({
    paymentId: v.string(),
  }),
})

export async function paymentWorkflow(applicationId: string) {
  "use workflow"

  const waitPayment = onPaymentCompletedHook.create({
    token: `onPayment:${applicationId}`,
  })

  // 決済完了の通知が来るまで待機する
  // create() の戻り値は thenable なので、関数呼び出しではなく await する
  const payment = await waitPayment

  await reserveSeat(applicationId)
  return payment
}

async function reserveSeat(applicationId: string) {
  "use step"
  // 参加枠を確保する
}
```

```ts:actions/resume-payment.ts
import { onPaymentCompletedHook } from "../workflows/payment-workflow"

// resume は workflow 外から呼ぶ
export async function resumePayment(applicationId: string, paymentId: string) {
  await onPaymentCompletedHook.resume(`onPayment:${applicationId}`, {
    paymentId,
  })
}
```

hookのtokenは一意である必要があります。一方でresumeする側は、そのtokenを特定できなければいけません。`onPayment:${applicationId}` のように、後から復元できる規則で作るのが安全です。

気をつける点としては、次もあります。

- `sleep` と `hook.create()` はworkflow内で使う
- `hook.resume()` はworkflow外で使う
- `fetch` などの外部呼び出しはstep内で使う
- while loop内にstepを入れると、`sleep` まわりで不具合が出やすい



## プロセスマネージャーパターンとの対応

少し経ってDDDの書籍を読んでいたとき、プロセスマネージャーパターンを知りました。

プロセスマネージャーは、だいたい次の役割を持ちます。

- 複数の境界づけられたコンテキストをまたぐ
- イベントを受け取る
- 状態を保持する
- 次に実行すべきコマンドを別のコンテキストへ送る

先ほどのイベント運営の例だと、申込み・決済・参加者管理・コミュニティ・通知はそれぞれ別の責務です。1つのサービスが全部知るべきではありません。

そこで必要になるのが、プロセス全体を管理する役割です。

- 決済が終わったら参加者管理へ登録する
- 参加者登録が終わったらDiscordへ招待する
- 開催前日になったら通知する

これがプロセスマネージャーです。

![プロセスマネージャーパターン](https://static.zenn.studio/user-upload/9b5f3c1dc750-20260707.png)
*プロセスマネージャーパターン*

Vercel Workflowの対応関係は、だいたい次のように見えます。


| プロセスマネージャー        | Vercel Workflow  |
| ----------------- | ---------------- |
| プロセス全体のオーケストレーション | `"use workflow"` |
| 各コンテキストへのコマンド実行   | `"use step"`     |
| 外部イベントの受信         | `hook`           |
| 時間待ち              | `sleep`          |
| プロセス状態の保持         | Workflow の実行状態   |


自分が使いやすいと感じた理由は、便利機能の多さというより、プロセスマネージャーという設計をそのまま実装しやすい実行基盤だったからだと考えています。

## 設計の見え方の変化

以前は「業務フローにはVercel Workflowが便利」という理解でした。

今は、まず次を確認するようにしています。

- この業務は複数のコンテキストをまたぐ長いプロセスか

そうであれば、プロセスマネージャーパターンとして設計し、その実装先としてVercel Workflowを選ぶ、という順番で考えるようになりました。

## まとめ

- 待機・リトライ・途中失敗を含む長い業務フローは、APIを順番に呼ぶだけでは破綻しやすい
- Vercel Workflowは `"use workflow"` / `"use step"` / `sleep` / `hook` で長いプロセスを書ける
- その役割は、プロセスマネージャーパターンと対応する
- ツール選定の前に、複数コンテキストをまたぐ長いプロセスかどうかを確認すると設計が整理しやすい

実装から入って後から設計パターンを知る、という経験もありました。便利なツールを選んだつもりが、実は設計パターンに沿った実装をしていた、という整理です。

この記事が、長い業務フローの実装やVercel Workflowの用途を検討している方の参考になれば幸いです。