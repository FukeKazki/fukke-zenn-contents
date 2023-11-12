---
title: "yabaiとskhdで快適ウィンドウ操作"
emoji: "🎃"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: []
published: false
---

# yabaiのインストール

# yabaiの設定

基本的なウィンドウ配置の設定です。

```bash:yabairc
yabai -m config \
    top_padding                  0             \
    bottom_padding               0             \
    left_padding                 0             \
    right_padding                0             \
    window_gap                   0             \
```

ウィンドウの透明化。

```bash:yabairc
yabai -m config                                 \
    window_opacity               on             \
    window_opacity_duration      0.0            \
    active_window_opacity        1.0            \
    normal_window_opacity        0.85           \
```

# skhdのインストール

# skhdでyabaiを操作

window間の移動。

```bash:skhdrc
alt - h : yabai -m window --focus west || yabai -m window --focus east
alt - l : yabai -m window --focus east || yabai -m window --focus west
alt - k : yabai -m window --focus north || yabai -m window --focus south
alt - j : yabai -m window --focus south || yabai -m window --focus north
```

スペース間の移動。

```bash:skhdrc
ctrl - 1 : yabai -m space --focus 1
ctrl - 2 : yabai -m space --focus 2
```

modeをつかったリサイズ。

```bash:skhdrc
:: resize @
ctrl - r ; resize
resize < ctrl - r ; default
resize < h : yabai -m window --resize left:-20:0 || yabai -m window --resize right:-20:0
resize < j : yabai -m window --resize bottom:0:-20 || yabai -m window --resize top:0:-20
resize < k : yabai -m window --resize top:0:20 || yabai -m window --resize bottom:0:20
resize < l : yabai -m window --resize right:20:0 || yabai -m window --resize left:20:0
```

ピクチャインピクチャ。

```bash:skhdrc
alt - p : yabai -m window --toggle sticky --toggle topmost --toggle pip
```

# tips

## yabaiに管理されたくないアプリの登録

MacのFinderの用なアプリでは、yabaiに管理されたくありません。
以下の設定で可能です。

```bash:yabairc
yabai -m rule --add app="^(Finder)$" manage=off
```
