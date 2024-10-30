---
title: "Firebase Remote ConfigでFeature Flagを管理する"
emoji: "🕌"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Firebase"]
published: true
publication_name: "yoshinani_dev"
---

## はじめに
機能開発とデプロイの両方を円滑に進めるために、Feature Flagの運用を始めました。

Feature Flagとは機能のON/OFFを切り変えるフラグをコード内に埋め込む運用のことです。
Feature Flagを用いることで、機能を隠しながらリリースしビックバンリリースを防いだり、一部ユーザーにのみ機能を公開するようなことができます。

今回はFirebse Remote ConfigとNextJSを使ったFeature Flagの管理について執筆します。

## Firebase Remote Config
Firebase Remote ConfigはFirebase上でパラメータを管理して配信できるサービスです。
今回はフューチャートグル機能をつかってFeature Flagを作成します。
他にもユーザーセグメントを作成してセグメントごとにパラメータを設定したり、ABテストのようなことも可能なサービスです。

![](https://storage.googleapis.com/zenn-user-upload/75439dc55755-20241022.png)

## Feature Flagを作成
例として課金実装のためのFlagを作成します。
データ型をブール値にして作成するとFlagとして運用できます。デフォルト値はfalseにしています。

![](https://storage.googleapis.com/zenn-user-upload/d235a7410a4b-20241022.png)

## Nextjsからの利用

`useFeatureFlag`フックを作成し以下のように利用できることを目指します。

```jsx
const { isBillingEnabled } = useFeatureFlag()
```

`FeatureFlagContext`と`FeatureFlagProvider`を作成します。

```jsx
import { fetchAndActivate, getRemoteConfig, getValue } from 'firebase/remote-config'
import { createContext, type ReactNode, useContext, useEffect, useState } from 'react'

interface FeatureFlagContext {
  isBillingEnabled: boolean
}
const FeatureFlagContext = createContext<FeatureFlagContext | undefined>(undefined)

export const FeatureFlagProvider = ({ children }: { children: ReactNode }) => {
  const [isBillingEnabled, setBillingEnabled] = useState(false)

  useEffect(() => {
    const remoteConfig = getRemoteConfig()

    const initializeRemoteConfig = async () => {
      try {
        // Remote Config バックエンドに接続する前にアプリを意図したとおりに動作させるためのデフォルト値
        remoteConfig.defaultConfig = {
          isBillingEnabled: false
        }

        await fetchAndActivate(remoteConfig)

        // リモートの値を取得
        const remoteBillingEnabled = getValue(remoteConfig, 'isBillingEnabled').asBoolean()
        setBillingEnabled(remoteBillingEnabled)
      } catch (error) {
        console.error('Error fetching remote config:', error)
      }
    }

    initializeRemoteConfig()
  }, [])

  return (
    <FeatureFlagContext.Provider value={{ isBillingEnabled }}>
      {children}
    </FeatureFlagContext.Provider>
  )
}

export const useFeatureFlag = () => {
  const context = useContext(FeatureFlagContext)

  if (!context) {
    throw new Error('useFeatureFlag must be used within a FeatureFlagContext')
  }

  return context
}
```

## ローカル管理画面で切り変えられるように
課金機能を実装している人目線ではフラグをONにしておきたいです。そのためにローカルストレージでもフラグを管理し、ローカルの値を優先するような設定を追加します。

```jsx
// リモートの値を取得
const remoteBillingEnabled = getValue(remoteConfig, 'isBillingEnabled').asBoolean()
// localStorage の値を確認して、優先的に使用
const localBillingEnabled = Boolean(localStorage.getItem('isBillingEnabled'))

// localStorage に値があればその値を使用し、なければリモートの値を使用
setBillingEnabled(
    localBillingEnabled !== null ? localBillingEnabled : remoteBillingEnabled
)
```

以下のようなページを用意すれば開発者ごとにフラグのON/OFFが可能です。

![](https://storage.googleapis.com/zenn-user-upload/b5be4549a1f0-20241022.png)

## Remote Configをファイルで管理
本番環境と開発環境でプロジェクトを分けているなど複数プロジェクトで運用している場合はRemote Configの値をファイルで管理しインポート/エクスポート機能を使い整合性を取ることができます。

![](https://storage.googleapis.com/zenn-user-upload/7d2dec2ba7dc-20241022.png)

## おわりに
Feature Flagで良い運用ライフをお過ごしください!
