---
title: "受託案件におけるリリース管理方法"
emoji: "❤️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["githubactions"]
published: false
publication_name: "yoshinani_dev"
---

## はじめに

GitHub ReleaseとGitHub Actionsを利用し、受託案件におけるリリース管理の効率化を図る方法を解説します。

## 要約

- ブランチ運用の改善: releaseブランチを導入し、developブランチのマージを停止することなく、リリース確認中も開発を継続できるようにしました。 GitHub Releaseの導入: Release起点のCI/CDを作成しました。リリースノートの自動生成機能により、リリースの差分が確認しやすくなりました。

## 課題

弊社のとある案件では、毎週リリースしています。これまでは、以下のようなブランチ運用をしていました。

```mermaid
graph RL;
    B[develop] --> A[main]
    C[feature/a] --> B
    D[feature/b] --> B
    B --> I>dev環境]
    A --> J>prod環境]
```

- prod環境: 本番稼働している環境
- dev環境: クライアント側で確認作業を行う環境

上記のフローでは、開発ブランチであるdevelopが直接dev環境に反映されるため、確認中にdevelopブランチの変更が反映されてしまい、確認フェーズでのブロッキングが発生します。そのため、確認中はマージを停止したり、開発を中断する必要がありました。

## 改善

そこで、運用フローを改善し、GitHub Releaseを使用するようにしました。

```mermaid
graph RL;
    E --> A[main]
    E --> G[deploy/dev]
    E --> L[Releaseの作成]
    L --> J>prod環境]
    B[develop] --> E[release/v1.2]
    C[feature/a] --> B
    D[feature/b] --> B
    G --> I>dev環境]
```

改善後の運用フローでは、releaseブランチを導入し、prod環境への反映にGitHub Releaseを活用するようにしました。releaseブランチを導入することで、developブランチのマージを停止する必要がなくなり、確認中も開発を継続できるようになりました。

### GitHub Releaseの利用

GitHub Releaseについて説明します。

Releaseは、ブランチやタグを選択して作成できます。
![](https://storage.googleapis.com/zenn-user-upload/97454c0b4f2d-20241105.png)

タグを作成。
![](https://storage.googleapis.com/zenn-user-upload/c61c02a419bd-20241105.png)

「Generate Release notes」ボタンでリリースノートが作成されます。
![](https://storage.googleapis.com/zenn-user-upload/94416f498cac-20241105.png)

v1.0をリリース。
![](https://storage.googleapis.com/zenn-user-upload/f727f18cba37-20241105.png)

### GitHub actionsの設定

GitHub Releaseが公開されたときにデプロイするCIは以下のトリガーで作成できます。

```yml:deploy.yml
name: Deploy
on:
  release:
    types: [published]
```

これによりReleaseの公開→デプロイというフローを作成できます。

## おわりに

GitHub Releaseを活用し、開発フローを改善しました。リリースノートの自動生成機能により、差分確認も容易になりました。ぜひ導入を検討してみてください。
