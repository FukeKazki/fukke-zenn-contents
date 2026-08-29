---
title: "Vite+でライブラリを作成し公開する"
emoji: "📚"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["npm", "vite"]
published: true
---

Vite+では`vp create`コマンドでライブラリのテンプレートを選択できます。
今回はそれを利用し、実際にnpmにライブラリを公開した手順について紹介します。

### 環境

| ツール名 | バージョン |
| --- | --- |
| vp | v0.3.0 |


## プロジェクトを作成する
`vp create`コマンドを実行し、Monorepo・Application・Libraryからテンプレートを選択します。
今回は`Vite+ Library`を選択します。

```bash
❯ vp create
VITE+ - The Unified Toolchain for the Web

  › Vite+ Monorepo: Create a new Vite+ monorepo project
    Vite+ Application: Create vite applications
    Vite+ Library: Create vite libraries
```

`Vite+ Library`を選択後、`パッケージ名`・`package manager`・`coding agent`・`editor`・`gitの初期化`・`pre-commitの設定`の設定をします。
今回は`stack`というパッケージ名にしました。

```bash
❯ vp create
VITE+ - The Unified Toolchain for the Web

  Vite+ Library

◇ Package name:
  stack

◇ Which package manager would you like to use?
  pnpm

◇ Which coding agent instruction files should Vite+ create?
  AGENTS.md

◇ Which editors are you using?
    Writes editor config files to enable recommended extensions and Oxlint/Oxfmt integrations.
  VSCode

◇ Initialize a git repository?
  Yes

◇ Set up pre-commit hooks to run formatting, linting, and type checking with auto-fixes?
  Yes

◇ Scaffolded stack with TypeScript library
• Node 24.20.0  pnpm 11.24.0
✓ Dependencies installed in 4.1s
→ Next: cd stack && vp run
```

コマンドの実行が完了するとプロジェクトが作成されます。
ディレクトリ構造を下記に示します。

```bash
.
├── AGENTS.md
├── node_modules
├── package.json
├── pnpm-lock.yaml
├── pnpm-workspace.yaml
├── README.md
├── src
│   └── index.ts
├── tests
│   └── index.test.ts
├── tsconfig.json
└── vite.config.ts
```

`vp --version`で導入されているツールを確認できました。
`vitest`や`oxfmt`・`oxlint`・`tsdown`などライブラリを開発する上で必要になるパッケージがデフォルトで入っていて、モダンな構成になっています。

```bash
❯ vp --version
VITE+ - The Unified Toolchain for the Web

vp v0.3.0

Local vite-plus:
  vite-plus  v0.3.0

Tools:
  vite             v8.2.2
  rolldown         v1.2.5
  vitest           v4.1.11
  oxfmt            v0.64.0
  oxlint           v1.79.0
  oxlint-tsgolint  v7.0.2001
  tsdown           v0.22.14

Environment:
  Package manager  pnpm v11.24.0
  Node.js          v24.20.0
```

## Stackを実装する
`tests/index.test.ts`が用意されているため、まずはテストを記述します。

```ts:tests/index.test.ts
import { expect, test } from "vite-plus/test";
import { Stack } from "../src/index.ts";

test("Stack", () => {
  const stack = new Stack<number>();
  stack.push(1);
  stack.push(2);
  expect(stack.pop()).toBe(2);
  expect(stack.pop()).toBe(1);
  expect(stack.pop()).toBe(undefined);
});
```

テストの実行は`pnpm test`です。
下記のように`vitest`が実行されます。
Redになったので中身を実装します。

```bash
❯ pnpm test
$ vp test

 RUN  v4.1.11 /Develop/stack

 ❯ tests/index.test.ts (1 test | 1 failed) 2ms
   × Stack 1ms

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

 FAIL  tests/index.test.ts > Stack
TypeError: Stack is not a constructor
 ❯ tests/index.test.ts:5:17
      3|
      4| test("Stack", () => {
      5|   const stack = new Stack();
       |                 ^
      6|   stack.push(1);
      7|   stack.push(2);

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯


 Test Files  1 failed (1)
      Tests  1 failed (1)
   Start at  14:04:11
   Duration  85ms (transform 11ms, setup 0ms, import 17ms, tests 2ms, environment 0ms)

[ELIFECYCLE] Test failed. See above for more details.
```

`src/index.ts`にStackを実装しました。

```ts:src/index.ts
export class Stack<T> {
  private items: T[] = [];
  push(item: T): void {
    this.items.push(item);
  }
  pop(): T | undefined {
    return this.items.pop();
  }
}
```

再度テストを実行します。
無事Greenになったので実装完了です。

```bash
❯ pnpm test
$ vp test

 RUN  v4.1.11 /Develop/stack

 ✓ tests/index.test.ts (1 test) 1ms
   ✓ Stack 1ms

 Test Files  1 passed (1)
      Tests  1 passed (1)
   Start at  01:36:17
   Duration  79ms (transform 9ms, setup 0ms, import 15ms, tests 1ms, environment 0ms)

```

format、lint、type checkは`pnpm check`で確認します。

```bash
❯ pnpm check
$ vp check
pass: All 10 files are correctly formatted (182ms, 15 threads)
pass: Found no warnings, lint errors, or type errors in 3 files (165ms, 15 threads)
```

## 公開準備

バンドルするため`pnpm build`を実行します。
生成物は`dist/`に作成されます。

```bash
❯ pnpm build
$ vp pack
ℹ entry: src/index.ts
ℹ tsconfig: tsconfig.json
ℹ Build start
ℹ Cleaning 2 files
warn: TypeScript 7.0 does not yet have a stable API and is experimental. Some options will be unavailable.
ℹ Emit types with typescript@7.0.2
ℹ dist/index.mjs    0.17 kB │ gzip: 0.14 kB
ℹ dist/index.d.mts  0.14 kB │ gzip: 0.13 kB
ℹ 2 files, total: 0.31 kB
✔ Build complete in 110ms
```

公開のために`package.json`を書き変えます。
`name`・`version`・`description`・`homepage`・`bugs`・`author`・`repository`をそれぞれ設定しました。
`README.md`も必要に応じて編集します。

```json:package.json
  "name": "@fukke0906/stack",
  "version": "0.1.0",
  "description": "A simple stack",
  "homepage": "https://github.com/FukeKazki/stack#readme",
  "bugs": {
    "url": "https://github.com/FukeKazki/stack/issues"
  },
  "license": "MIT",
  "author": "FukeKazki",
  "repository": {
    "type": "git",
    "url": "git+https://github.com/FukeKazki/stack.git"
  },
```

## 公開
`pnpm whoami`でnpmの認証情報を確認します。

```bash
❯ pnpm whoami
[ERR_PNPM_WHOAMI_FAILED] Failed to find the current user: 401 Unauthorized
```

未認証の場合は、`pnpm login`でnpmアカウントにログインします。認証済みの場合は`pnpm whoami`でユーザー名が出力されました。
```bash
❯ pnpm login
❯ pnpm whoami
fukke0906
```

公開前に`pnpm publish --dry-run`でどんな形で公開されるか確認できます。
`@fukke0906/stack@0.1.0`で公開されることがわかりました。

```bash
❯ pnpm publish --dry-run
$ vp run build
$ vp pack ⊘ cache disabled
ℹ entry: src/index.ts
ℹ tsconfig: tsconfig.json
ℹ Build start
ℹ Cleaning 2 files
warn: TypeScript 7.0 does not yet have a stable API and is experimental. Some options will be unavailable.
ℹ Emit types with typescript@7.0.2
ℹ dist/index.mjs    0.17 kB │ gzip: 0.14 kB
ℹ dist/index.d.mts  0.14 kB │ gzip: 0.13 kB
ℹ 2 files, total: 0.31 kB
✔ Build complete in 113ms

$ vp config
📦 @fukke0906/stack@0.1.0 → https://registry.npmjs.org/
[WARN] Skip publishing @fukke0906/stack@0.1.0 (dry run)
```

最後にGitHubにrepositoryを作成しpush後、`pnpm publish`で公開します。

![@fukke0906/stack@0.1.0がnpmに公開された様子](https://static.zenn.studio/user-upload/6023328f9841-20260829.png)
*@fukke0906/stack@0.1.0がnpmに公開された様子*

## まとめ
Vite+の`Library`テンプレートを使ってnpmにパッケージを公開しました。
Vite+を使うことでライブラリ作成に必要な環境を簡単に手に入れられる点に良さを感じました。
npmのライブラリ作成時に参考になれば幸いです。