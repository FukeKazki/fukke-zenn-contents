---
title: "wordpress pluginをつくることになったときのtips"
emoji: "🔥"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: []
published: false
---

## プロジェクトの構成

composerで作成する。
`plugin`ディレクトリを作成し、そこに`plugin-name.php`を作成する。

## プラグインの配布
wordpress pluginはzipで配布する。
makefileにzipを作成するコマンドを追加する。

```makefile
DIR_NAME = $(shell basename $(shell pwd)) 

all: zip

zip:
	composer install --no-dev
	zip -r $(DIR_NAME) . -x '.git/*' '.gitignore' 'makefile' '.php-cs-fixer.php' '.php-cs-fixer.cache' 'README.md' 'composer.lock' 'composer.json' '*.zip'

.PHONY: all zip
```

## リント系の導入
phpstan,php-cs-fixerを導入する。
