---
title: "値オブジェクトの実装パターン - Backend TypeScript"
emoji: "🐈"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["typescript", "valibot"]
published: true
---

## はじめに

値オブジェクトを作ると、そのオブジェクトの存在自体が、パース済みで完全な状態であることを保証してくれます。
そのため、色々なところでパース処理がでてきたり、パースされていない状態のオブジェクトが存在したりするようなアンチパターンを防げます。

今回はそんな値オブジェクトの実装パターンについて紹介します。

## 使用技術

使用技術は下記です。

- TypeScript
- valibot
- vitest
- `@nakanoaas/tagged-error`（`TaggedError`）: エラー処理用のライブラリ。custom error classと読み替えてもらってかまいません

Classを利用しない関数型のアプローチを採用しています。

## ColorCode値オブジェクトの実装

タグ作成機能があったとして、タグに色を設定できることを想定してColorCode値オブジェクトを実装します。
ColorCode値オブジェクトの制約は、先頭が`#`から始まり16進数の文字が6桁あることです。

スキーマはvalibotを利用して定義します。
valibotのスキーマは`v.safeParse`メソッドでパースができるため、値オブジェクトの定義と検証に便利です。

`constructColorCode`はColorCodeオブジェクトを生成する際に利用する関数です。
パースに失敗した場合はエラーを返すため、不正な状態のオブジェクトが存在することを防げます。
戻り値は成功時が`ColorCode`、失敗時が`TaggedError`のユニオン型になるため、呼び出し側は型で成功と失敗を判別できます。これにより、不正な状態の値が型レベルで存在しなくなります。

```ts:color-code.ts
import { TaggedError } from "@nakanoaas/tagged-error"
import * as v from "valibot"

export const ColorCodeSchema = v.pipe(
  v.string(),
  v.regex(/^#([0-9a-fA-F]{6})$/),
)
export type ColorCode = v.InferOutput<typeof ColorCodeSchema>

export const constructColorCode = (color: string) => {
  const result = v.safeParse(ColorCodeSchema, color)
  if (!result.success) {
    return new TaggedError("INVALID_COLOR_CODE", {
      message: "不正なカラーコードです",
      cause: result.issues,
    })
  }
  return result.output
}
```

テストコードは下記のようになります。

```ts:color-code.spec.ts
import { TaggedError } from "@nakanoaas/tagged-error"

import { constructColorCode } from "./color-code"

describe("ColorCodeのテスト", () => {
  describe("constructColorCodeのテスト", () => {
    it("#RRGGBB形式の正しいカラーコードは通る", () => {
      expect(constructColorCode("#ffcc00")).toBe("#ffcc00")
      expect(constructColorCode("#123ABC")).toBe("#123ABC")
      expect(constructColorCode("#000000")).toBe("#000000")
      expect(constructColorCode("#FFFFFF")).toBe("#FFFFFF")
    })

    it("#RRGGBB以外はTaggedErrorを返す", () => {
      const invalids = [
        "#fff", // 3桁
        "#ffcc0011", // 8桁
        "#ffcc0", // 5桁
        "123456", // #なし
        "#GGGGGG", // 16進数以外
        "", // 空
        "#12345G", // 16進数以外
      ]
      invalids.forEach((code) => {
        const result = constructColorCode(code)
        expect(result instanceof TaggedError).toBe(true)
      })
    })
  })
})
```

## 誕生日値オブジェクトの実装

ユーザーの誕生日を入力してもらうようなサービスでの、誕生日値オブジェクトの実装です。

未来の誕生日を登録できないことを制約にしています。

```ts:birthday.ts
import { TaggedError } from "@nakanoaas/tagged-error"
import * as v from "valibot"

export const BirthdaySchema = v.pipe(
  v.date(),
  v.maxValue(new Date(), "誕生日は未来の日付にできません"),
)
export type Birthday = v.InferOutput<typeof BirthdaySchema>

export const constructBirthday = (birthday: Date) => {
  const result = v.safeParse(BirthdaySchema, birthday)
  if (!result.success) {
    return new TaggedError("INVALID_BIRTHDAY", {
      message: "不正な誕生日です",
      cause: result.issues,
    })
  }
  return result.output
}
```

## まとめ

値オブジェクトを、valibotと関数型のアプローチを組み合わせて実装するパターンについて紹介しました。

値オブジェクトは、実世界に存在する不変な概念や、エンティティが持つ単体の属性に対して作成するのがよいと考えています。

値オブジェクトパターンは実装が簡単な上、効果が絶大なため、積極的に取り入れてみてください。