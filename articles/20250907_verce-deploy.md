---
title: "Vercelの機能を活用してブランチ運用をシンプルなままリリースを管理する方法"
emoji: "🤖"
type: "tech"
topics: ["vercel"]
published: true
publication_name: "yoshinani_dev"
---


> この記事は「YOSHINANI&ねこねこパラダイス Advent Calendar 2025」の8日目です。https://adventar.org/calendars/12110

株式会社YOSHINANIのふっけです。
今回は、Vercelの機能を活用してブランチ運用をシンプルなままリリースを管理する方法を紹介します。

この記事を読むことで、mainとfeatureブランチのみのシンプルな運用のまま、「いつ本番に出すか」をVercel上でコントロールできるようになります。

## 目指す運用フロー
下記の環境を用意します。

- Production本番環境
- Staging本番環境の事前確認用
- Development開発環境
- Preview PRごとの開発環境

日々の流れは以下のようにします。

1. featureブランチで実装し、PRの作成、Preview環境で動作確認
2. コードレビューの承認後、mainブランチにマージ
3. Staging環境でリリース前の確認
4. 問題なければPromote to Productionで本番環境にデプロイ
5. リリース後に、問題があれば過去のProductionデプロイにロールバックする

![Production、Preview、Stagingのデプロイが作成されている](https://storage.googleapis.com/zenn-user-upload/1c93ed3ec859-20251207.png)
_Production、Preview、Stagingのデプロイが作成されている_

![Promoteボタンで任意のデプロイを公開できる](https://storage.googleapis.com/zenn-user-upload/f3939f40c6a8-20251207.png)
_Promoteボタンで任意のデプロイを公開できる_


## Vercelの設定
上記の運用フローを達成するために、Vercelの設定をしていきます。

デフォルトの環境定義は以下のようになっています。

| 環境名 | デプロイ方法 |
| --- | --- |
| Production | main branchをトラッキングし自動でデプロイ |
| Development | CLI経由 |
| Preview | PRごとに作成される |

ここに以下の変更を加えます。

| 差分 | 環境名 | デプロイ方法 |
| --- | --- | --- |
| 編集 | Production | Auto-assign Custom Production Domainsを外す |
| 追加 | Staging | main branchのトラッキング |

まず、Staging環境を新たに作成し、main branchをトラッキングするようにします。

![EnvironmentにStagingを追加した様子](https://storage.googleapis.com/zenn-user-upload/10581107d755-20251207.png)
_EnvironmentにStagingを追加した_

これによってmainにマージされた最新のコードがStaging環境に反映されるようになります。

次にProduction環境のAuto-assign Custom Production DomainsをOFFにします。
![ProductionのAuto-assign Custom Production DomainsをOFFにした](https://storage.googleapis.com/zenn-user-upload/5fd6125cf35c-20251207.png)
_ProductionのAuto-assign Custom Production DomainsをOFFした_



## 機能追加にどう対応するか
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

この記事では、ブランチ構成を増やすのではなく、Vercelの機能だけで「マージ」と「リリース」を分離して運用する方法を紹介しました。

- mainをトラッキングするStaging環境を用意する
- ProductionのAuto-assign Custom Production Domainsを外し、Promote to Productionで本番に出すデプロイを選ぶ
- Vercel Edge ConfigによるFeature Flagで、mainに含めた開発中機能の公開タイミングをコントロールする

これらを組み合わせることで、ブランチ運用はシンプルにしたまま、本番リリースの安全性と柔軟性を高めることができます。

この記事がVercelでの運用を採用している方々の参考になれば幸いです。
