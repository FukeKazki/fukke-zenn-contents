---
title: "受託小規模向けの技術選定と考えたこと"
emoji: "🕌"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["nextjs"]
published: true
---


## なぜ使い回せる技術構成が必要か
受託開発では、短い期間で成果を出しつつ品質の高いものを作ることが大切です。
そのためには、案件ごとに技術スタックの検討にかける時間をなるべく減らし、その分を要件定義や設計に充てられる状態が理想です。
品質の高いものを低コストで出せる技術構成には、それ自体に価値があります。
今回はそうした技術構成を考え、ある程度運用してきたので紹介します。

## 想定するチームと設計の軸
受託企業の小人数チーム（フロントエンド2名・バックエンド1名を想定）で最適化された設計です。
小規模から中規模のアプリケーション開発を対象に、次の4つを思想として構成を組んでいます。
- 初期構築が早い
- 依存しているサービスが少ない
- 幅広い要件に対応できる
- ランニングコストが低い

## 採用した技術スタック
結論としては、フレームワークにNext.jsを利用し、PaaSとしてVercelとSupabaseを組み合わせています。
Vercelはデプロイ環境としての利用に加え、フィーチャーフラグが必要な場合はVercel Edge Config、定期実行が必要な場合はVercel Cronを使っています。
Supabaseはストレージが必要な場合にSupabase Storage、データベースにSupabase Postgresを利用しています。
認証ライブラリにはbetter-authを利用しています。
アーキテクチャとしてはpnpm workspaceを使ったモノレポで、Next.jsを使ってフロントエンドからバックエンドまで一貫してTypeScriptで作ることを目指しました。
まとめると、技術スタックは次のとおりです。

- PaaS
  - Vercel
    - Vercel Edge Config（フィーチャーフラグ）
    - Vercel Cron（定期実行）
  - Supabase
    - Supabase Postgres（データベース）
    - Supabase Storage（ストレージ）
- Framework
  - Next.js
- 認証
  - better-auth

## VercelとSupabaseを選んだ理由
選定理由の第一は、Vercel・Supabaseともに構築が速いことです。
VercelはGitHub Actionsと連携し、CI/CDですぐにデプロイ環境を作れます。周辺エコシステム（Vercel CronやVercel Edge Config）も充実している点が気に入っています。
SupabaseはPostgreSQLをすばやく構築でき、Supabase CLIでローカル環境も簡単に用意できます。ローカルでも同じ構成のデータベース・ストレージを作れる点も魅力です。

### ランニングコストの目安
※料金は執筆時点のものです。詳細は[Vercel Pricing](https://vercel.com/pricing)と[Supabase Pricing](https://supabase.com/pricing)を参照してください。

VercelはOrganizationのProプランの場合、エンジニア招待が1人あたり$20かかり、Functionの起動数・帯域による従量課金も発生します。
案件規模によりますが、小規模であればOrganizationの無料クレジット内に収まることも多いです。
SupabaseはOrganizationのProが月$25で、Projectごとに最小構成で$10かかります。開発と本番で2 Project使うと、あわせて$20必要です。

例えばどちらも1つのOrganizationを流用し、Vercel側は無料クレジット内に収まる前提で運用した場合を考えます。このとき、Supabaseの開発・本番の2 Projectで月$20が下限のランニングコストになります。

## モノレポとfeature単位のアーキテクチャ
リポジトリ構成は、pnpm workspaceを使ったモノレポです。`apps`配下に`web`のようなアプリケーションを配置し、`packages`配下には共通モジュールを置きます。`packages/ui`にはドメイン知識を持たないUI（shadcnなどからコピーしたもの）を、`packages/schema`にはPrismaのようなORMまわりの定義を置いています。

思想としては、フロントエンドからバックエンドまで一貫してTypeScriptで記述することを重視しています。少ない人数・同じ技術スタックであれば、言語の切り替えコストを意識せずに実装できます。Next.jsのServer ActionやServer Componentを利用し、必要に応じて任意のアーキテクチャを適用できるようにしています。

複雑な要件やドメインがある箇所では、システムとしてもそれなりに複雑なアーキテクチャが必要になります。その場合はfeature単位で分割し、文脈ごとの複雑度に合わせてアーキテクチャを選べるようにしています。選択できるアーキテクチャの例は、DDD、layered architecture + Ports and Adapters、CQRS、transaction scriptです。

下記は基本的な構成です。`features`配下が、ドメインによってどのアーキテクチャを使うかを変えている箇所です。`auth`のように複数のコンテキストから参照されるものは、共有領域として`core/auth`に配置しています。`base/value-object`には、誕生日のように複数箇所から参照される普遍的な値の定義を置いています。フロントとサーバーの境界は`actions`が担っており、コンポーネントは`actions`を介してデータの取得・更新をします。

```text
/
├─ apps/
│  └─ web/
│     ├─ app/
│     │  └─ dashboard/
│     │     └─ todo-list/
│     │        ├─ _actions/
│     │        │  └─ create-task-action.ts
│     │        ├─ _components/
│     │        │  └─ task-list/
│     │        │     ├─ index.tsx
│     │        │     └─ presentation.tsx
│     │        ├─ page.tsx
│     │        └─ new/
│     │           ├─ page.tsx
│     │           └─ presentation.tsx
│     ├─ libs/
│     │  └─ safe-action.ts
│     └─ features/
│        ├─ base/
│        │  └─ value-object/
│        │     └─ birthday/
│        ├─ core/
│        │  └─ auth/
│        └─ task/
│           ├─ read/
│           │  └─ handler/
│           └─ write/
│              ├─ domain/
│              └─ usecase/
├─ packages/
│  ├─ ui/
│  └─ schema/
└─ supabase/
```

## この構成が向かないケース
大規模SaaS開発など可用性をしっかり考える必要がある場合は、AWSやGCPでインフラを組む方がいいです。
また、この構成はTypeScriptのコンテキストに強いエンジニアが揃っていたから機能した面があります。
例えばバックエンド専任がいるチームで、フロントエンドとバックエンドで役割を棲み分けたい場合は、この構成にこだわる必要はありません。

## おわりに
受託の文脈での設計について紹介しました。
設計はチームメンバーのスキルや技術のコンテキストによっても変わってくるので、チームや組織に合った技術選定が大事になります。
この記事が技術選定の参考になれば幸いです。
