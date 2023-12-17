---
title: "Raspberry Pi Picoでつくる電光掲示板"
emoji: "🪅"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [raspberrypi]
published: false
publication_name: "chot"
---

https://adventar.org/calendars/8910
ちょっと株式会社アドベントカレンダー 12月18日の記事です。

この記事ではRaspberry Pi Pico(以下ラズパイピコと呼ぶ)を使ってLEDMatrixPanelを制御します。

# ラズパイピコの購入

ラズパイピコはC/C++やMicroPythonでプログラミングできるマイコンボードです。
AliExpressというECサイトで購入しました。
日本語表記が怪しいですが、問題なく届きました。
![](https://storage.googleapis.com/zenn-user-upload/6ba580549401-20231212.png)

# ラズパイピコとPCの接続

PCとラズパイピコをUSBケーブルで接続します。
[thonny](https://thonny.org/)というIDEを使ってプログラムを書き込みます。

接続確認のために、LEDを点灯させるプログラムを書き込みます。

```python:LED点灯プログラム
import machine
import time

led= machine.Pin('LED', machine.Pin.OUT)

while (True):
    led.on()
```

![](https://storage.googleapis.com/zenn-user-upload/1503025e901d-20231113.jpeg)
_LEDが点灯したラズパイ_

点灯が確認できたので、次はピンヘッダをはんだ付けします。

# ピンヘッダの取り付け

ラズパイピコにはGPIOという外部のセンサーやアクチュエーターを接続するための端子があります。
GPIOにピンヘッダをはんだ付けして接続しやすくします。

Amazonで安いはんだごてセットを購入しました。

![](https://storage.googleapis.com/zenn-user-upload/1837a77eaa85-20231212.png)
_安かったはんだごてセット_

ピンヘッダをブレッドボードに固定して、その上にラズパイピコを乗せてはんだ付けします。

| ブレッドボードに刺さったピンヘッダ                                                                               | ピンヘッダに刺したラズパイ                                                                               |
| ---------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| ![ブレッドボードに刺さったピンヘッダ](https://storage.googleapis.com/zenn-user-upload/bd530b7105a1-20231113.jpg) | ![ピンヘッダに刺したラズパイ](https://storage.googleapis.com/zenn-user-upload/0c857f367171-20231113.jpg) |

<!-- ![はんだ付け準備](https://storage.googleapis.com/zenn-user-upload/86362039a4ef-20231113.jpg) -->

はんだ付け後がこちら。はんだ付けは苦手なのであまり裏面を見せたくないけど...。

| はんだ付け後のラズパイ裏                                                                              | はんだ付け後のラズパイ表                                                                              |
| ----------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| ![はんだ付け後のラズパイ1](https://storage.googleapis.com/zenn-user-upload/0920a0d42b8f-20231113.jpg) | ![はんだ付け後のラズパイ2](https://storage.googleapis.com/zenn-user-upload/93d752ade0aa-20231113.jpg) |

# LEDMatrixPanelの購入

ラズパイピコから制御するLEDMatrixPanelを購入します。

今回は秋葉原のお店で購入しました。電源とケーブルも一緒に。
![](https://storage.googleapis.com/zenn-user-upload/073a68efd05c-20231212.png)
_LEDMatrixPanelと電源回り_

# LEDMatrixPanelの接続

パネルの裏面にはピンヘッダが付いているのでその表示を見ながらジャンパー線でラズパイピコに接続します。
詳細はデータシートを確認してください。

![ラズパイとマトリクスLEDの接続](https://storage.googleapis.com/zenn-user-upload/b6667b2a32b3-20231113.jpg)
_ラズパイとマトリクスLEDの接続_

接続できたら、プログラムを書き込んで動作確認します。

```python:任意の色を表示するプログラム
import machine
import time
# GPIOピンの設定
R0 = machine.Pin(0, machine.Pin.OUT)
G0 = machine.Pin(1, machine.Pin.OUT)
B0 = machine.Pin(2, machine.Pin.OUT)
R1 = machine.Pin(3, machine.Pin.OUT)
G1 = machine.Pin(4, machine.Pin.OUT)
B1 = machine.Pin(5, machine.Pin.OUT)
A = machine.Pin(6, machine.Pin.OUT)
B = machine.Pin(7, machine.Pin.OUT)
C = machine.Pin(8, machine.Pin.OUT)
CLK = machine.Pin(11, machine.Pin.OUT)
STB = machine.Pin(12, machine.Pin.OUT)
OEn = machine.Pin(13, machine.Pin.OUT)
# 行を選択する関数
def select_row(row):
    A.value(row & 0b0001)
    B.value((row >> 1) & 0b0001)
    C.value((row >> 2) & 0b0001)
# ピクセルの色を設定する関数
def set_pixel_color(r0, g0, b0, r1, g1, b1):
    R0.value(r0)
    G0.value(g0)
    B0.value(b0)
    R1.value(r1)
    G1.value(g1)
    B1.value(b1)
# 主要なループ
while True:
    for row in range(16):  # 16行
        select_row(row)
        for col in range(32): # 32列
            # ここで任意の色データをセット
            set_pixel_color(1, 1, 0, 0, 1, 0)  # 例: 上の半分は赤、下の半分は緑
            CLK.value(1)
            CLK.value(0)
        STB.value(1)
        STB.value(0)
        OEn.value(0)  # 出力を有効にする
        time.sleep(0.00001)  # この値を小さくしてリフレッシュレートを上げる
        OEn.value(1)  # 出力を無効にする
```

R0 G0 B0は上の半分、R1 G1 B1は下の半分のLEDを制御します。
A B Cは行を選択するためのピンです。
`(A, B, C) = (0, 0, 0)`のとき、1行目が選択されます。
`(R0, G0, B0, R1, G1, B1) = (1, 1, 0, 0, 1, 0)`のとき、上半分は赤、下半分は緑になります。
CLKを変化させて次のピクセルに進みます。
これを繰り返すことで画面全体を表示します。

| 表面                                                                           | 接続部分                                                                       |
| ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------ |
| ![](https://storage.googleapis.com/zenn-user-upload/6954cd68d1f0-20231212.png) | ![](https://storage.googleapis.com/zenn-user-upload/b7a554b1597b-20231212.png) |

そして無事にLEDMatrixPanelが点灯しました。🎄🎄
リフレッシュレートの関係で撮影するのは難しいですが、ちゃんと動作しています。

# おわりに

いかがでしたでしょうか。
街中にある電光掲示板もLEDMatrixPanelをたくさん繋げて作られています。
自分だけの電光掲示板を作ってみてください。

最近は32x32のLEDMatrixPanelを使って遊んでいます。

@[tweet](https://twitter.com/fukke0906/status/1717221703410242000)
