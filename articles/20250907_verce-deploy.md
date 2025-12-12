---
title: "main+featureだけで回すVercel運用：マージとリリースを分離する"
emoji: "🤖"
type: "tech"
topics: ["vercel"]
published: false
publication_name: "yoshinani_dev"
---


> この記事は「YOSHINANI&ねこねこパラダイス Advent Calendar 2025」の8日目です。https://adventar.org/calendars/12110

株式会社YOSHINANIのふっけです。
今回は、Vercelの機能を活用してブランチ運用をシンプルにする方法を紹介します。

この記事を読むことで、main と feature ブランチのみのシンプルな運用のまま、「いつ本番に出すか」をVercel上でコントロールできるようになります。

## 前提
下記の環境があることを想定します。

- Production
- Staging
- Development

## Vercelで「リリース環境」を管理する
### デフォルトの構成
Vercelのデフォルトでは環境定義は以下のようになっています。

| 環境名 | デプロイ方法 |
| --- | --- |
| Production | main branchをトラッキングし自動でデプロイ |
| Development | CLI経由 |
| Preview | PRごとに作成される |

ここに以下の変更を加えます。

| 差分 | 環境名 | デプロイ方法 |
| --- | --- | --- |
| edit | Production | Auto-assign Custom Production Domainsを外す |
| add | Staging | main branchのトラッキング |

![](https://storage.googleapis.com/zenn-user-upload/10581107d755-20251207.png)

## 目指す運用
やりたいことは次の2点だけです。

- mainにマージしても自動で本番公開しない（デプロイは作るが本番ドメインに紐づけない）
- 確認できたデプロイだけを、Vercelの操作で本番に昇格（Promote）する

まず、Staging環境を新たに作成し、main branchをトラッキングするようにします。
これによってmainにマージされた最新のコードがStaging環境に反映されるようになります。

次にProduction環境のAuto-assign Custom Production Domainsを外します。
![](https://storage.googleapis.com/zenn-user-upload/5fd6125cf35c-20251207.png)

これによって、mainにマージ時にデプロイは作成されますが、本番ドメインにアタッチされることはありません。

この状態でStaging環境などで十分に動作確認を行い、問題がないと判断できたタイミングで、Vercel上のPromote to Productionボタンを押します。  
そうすることで、その時点で選択したデプロイだけを本番URLにアタッチできます。

不具合が発生したときに即座に過去の本番デプロイへ戻すこともできます。

## 運用フロー（おすすめ）
日々の流れはこれで回ります。

1. featureブランチで実装 → PR作成（Previewで動作確認）
2. レビューOK → mainにマージ
3. Staging（main tracking）で結合後の確認
4. 問題なければ Promote to Production（この操作が“リリース”）
5. もし問題があれば、過去のProductionデプロイに戻す（ロールバック）

これによってブランチの運用は main と feature のみにして、デプロイ環境は Production / Staging / Development / Preview を準備できます。
![](https://storage.googleapis.com/zenn-user-upload/1c93ed3ec859-20251207.png)
![](https://storage.googleapis.com/zenn-user-upload/f3939f40c6a8-20251207.png)


## 機能追加にどう対応するか（Vercel Edge Config）
mainブランチにfeatureをマージする戦略のときに、開発中の機能のコードが含まれるのをどう扱うか、という悩みが出てきます。

ここでもVercelの機能を使います。VercelのEdge Config機能を使うとFeature Flag運用が可能です。

詳細な解説は省きますが、下記のようなコードとVercel上の設定でFeature Flagを利用できます。
Feature Flagを使って開発中の機能については動作しないように条件分岐することで、開発途中のコードもmainブランチに含めることができます。
また、徐々に機能を有効化できるため、ビッグバンリリースを防ぐことができます。

```ts:get-flag.ts
"server-only"

import { get } from "@vercel/edge-config"

const getFlag = (flag: string) => {
  return get(flag)
}

export const getFeatureAFlag = () => getFlag("isFeatureAEnable")
```

## まとめ

この記事では、ブランチ構成を増やすのではなく、Vercelの機能だけで 「マージ」と「リリース」を分離して運用する方法を紹介しました。

- mainをトラッキングするStaging環境を用意する
- ProductionのAuto-assign Custom Production Domainsを外し、Promote to Productionで本番に出すデプロイを選ぶ
- Vercel Edge ConfigによるFeature Flagで、mainに含めた開発中機能の公開タイミングをコントロールする

これらを組み合わせることで、ブランチ運用はシンプルにしたまま、本番リリースの安全性と柔軟性を高めることができます。

