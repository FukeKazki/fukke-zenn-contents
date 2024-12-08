---
title: "GitHub Actionsを活用した安心してマージできる取り組み"
emoji: "🎉"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["githubactions"]
published: true
publication_name: "yoshinani_dev"
---

## はじめに

フロントエンドの開発で弊社が取り組んでいるGitHub Actionsの活用方法を紹介します。
使用技術は`NextJS, Turborepo, pnpm`です。

## 要約

- pr-agentの導入: AIを活用したレビューでレビュワーの負担を下げました。
- TypeCheck,Lint,Build CIの作成: 基本的なCIを組みました。

## PRAgent

弊社は小規模なチーム構成で開発を進めているため、コードレビューがスキップされてマージされるケースがありました。これに対処するため、AIを活用したコードレビュー支援ツールであるPR Agentを導入しました。

PRAgentはGitHub Actions上で動かせるAIです。`OPENAI_KEY`を登録すればコード差分を見てAIがレビューしてくれます。
さらに、プロンプトの改善をし日本語対応やプロジェクト固有の事情を反映させた、より的確なレビューが可能です。
以下に設定の例を示します。

```yml:pr-agent.yml
on:
  pull_request:
    types: [opened, reopened, ready_for_review]
jobs:
  pr_agent_job:
    if: ${{ github.event.sender.type != 'Bot' }}
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
      contents: write
    name: Run pr agent on every pull request, respond to user comments
    steps:
      - name: PR Agent action step
        id: pragent
        uses: Codium-ai/pr-agent@main
        env:
          OPENAI_KEY: ${{ secrets.OPENAI_KEY }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          github_action_config.auto_describe: false
          github_action_config.auto_improve: true
          PR_CODE_SUGGESTIONS.EXTRA_INSTRUCTIONS: >-
            日本語で回答してください。
            使用技術は以下のようになっています。
            -  React, TypeScript, Node v20
            コーディング規約は以下のようになっているので、それに従ってください。
            - TypeScriptのコーディング規約(https://typescript-jp.gitbook.io/deep-dive/styleguide) に従います。
          github_action_config.auto_review: true
          PR_REVIEWER.EXTRA_INSTRUCTIONS: >-
            日本語で回答してください。
```

![](https://storage.googleapis.com/zenn-user-upload/2b86e2c44313-20241208.png)

## 基本的なCI

TypeCheck, Lint, BuildについてもGitHub Actionsで確認しています。
モノレポプロジェクトでのGitHub Actionsの設定について示します。

```yml:app.yml
name: Apps Chat CI

on:
  pull_request:
    paths:
      - 'apps/admin/**'

jobs:
  typecheck:
    name: Typecheck
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: '.tool-versions'
          cache: 'pnpm'
      - run: pnpm install
      - name: typecheck
        run: |
          cd apps/admin
          pnpm typecheck
  lint:
    name: Lint
    runs-on: ubuntu-latest steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: '.tool-versions'
          cache: 'pnpm'
      - run: pnpm install
      - name: lint
        run: |
          cd apps/admin
          pnpm lint
  build:
    name: Build
    runs-on: ubuntu-latest
    needs: [lint, typecheck]
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: '.tool-versions'
          cache: 'pnpm'
          cache-dependency-path: 'pnpm-lock.yaml'
      - run: pnpm install
      - name: build
        run: |
          pnpm build:admin
```

![](https://storage.googleapis.com/zenn-user-upload/5cfad0ac66f8-20241207.png)

### 依存パッケージのビルド

Turborepoを用いたモノレポ構成では、依存パッケージをビルドしてからメインアプリケーションをビルドする必要があります。そのため、postinstallフックを利用して依存パッケージのビルドを行いました。

`@repo/shared`をインストールしているときの例を示します。

```json:package.json
{
  "name": "@repo/shared",
  "scripts": {
    "postinstall": "pnpm run build",
    "build": "tsup --clean",
  },
```

### Dependabot

GitHub Actionsで利用する環境変数をrepository secretsで指定している場合、Dependabot経由で作成されたPRにおいてActions実行時に失敗することがありました。
そのため、Dependabot専用のsecretsを別途設定する必要があります。

![](https://storage.googleapis.com/zenn-user-upload/413ac6771249-20241207.png)

## おわりに

本記事では、GitHub Actionsを活用することで、安心してマージ可能な開発フローを整えた事例を紹介しました。AIによるコードレビュー支援や基本的なCIパイプラインの構築などを組み合わせることで、品質と生産性の向上を実現できます。
是非導入してみてください!
